#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::path::{Path, PathBuf};
use std::process::{Child, Command};

use eframe::egui;

/// 게임 한 개의 메타데이터 (apps/ 스캔으로 채움)
struct Game {
    id: String,        // 디렉터리 이름 (game-yjh-slither 등)
    author: String,    // yjh / pjh
    project_dir: PathBuf, // project.godot 이 있는 디렉터리
    is_multi: bool,    // -multi 접미사 → 서버/클라 분리 실행
}

/// 실행 중 프로세스 추적
struct Running {
    game_id: String,
    role: &'static str, // "플레이" | "서버" | "클라"
    child: Child,
}

struct App {
    games: Vec<Game>,
    godot: Option<PathBuf>,
    apps_dir: PathBuf,
    running: Vec<Running>,
    error: Option<String>,
}

fn find_godot() -> Option<PathBuf> {
    // PATH 의 godot / godot4 → mac 표준 앱 번들 순으로 탐색
    for name in ["godot", "godot4"] {
        if let Ok(out) = Command::new("which").arg(name).output() {
            if out.status.success() {
                let p = String::from_utf8_lossy(&out.stdout).trim().to_string();
                if !p.is_empty() {
                    return Some(PathBuf::from(p));
                }
            }
        }
    }
    let bundle = PathBuf::from("/Applications/Godot.app/Contents/MacOS/Godot");
    bundle.exists().then_some(bundle)
}

fn scan_games(apps_dir: &Path) -> Vec<Game> {
    let mut games = Vec::new();
    let Ok(entries) = std::fs::read_dir(apps_dir) else {
        return games;
    };
    for entry in entries.flatten() {
        let dir = entry.path();
        let Some(name) = dir.file_name().and_then(|n| n.to_str()).map(String::from) else {
            continue;
        };
        if !name.starts_with("game-") {
            continue;
        }
        // project.godot 위치: 루트(yjh) 또는 project/(pjh)
        let project_dir = if dir.join("project.godot").exists() {
            dir.clone()
        } else if dir.join("project/project.godot").exists() {
            dir.join("project")
        } else {
            continue;
        };
        let author = name.split('-').nth(1).unwrap_or("?").to_string();
        let is_multi = name.ends_with("-multi");
        games.push(Game { id: name, author, project_dir, is_multi });
    }
    games.sort_by(|a, b| a.id.cmp(&b.id));
    games
}

/// egui 기본 폰트에는 한글 글리프가 없어 시스템 폰트를 얹는다
fn install_korean_font(ctx: &egui::Context) {
    let path = "/System/Library/Fonts/Supplemental/AppleGothic.ttf";
    let Ok(bytes) = std::fs::read(path) else { return };
    let mut fonts = egui::FontDefinitions::default();
    fonts
        .font_data
        .insert("korean".into(), egui::FontData::from_owned(bytes).into());
    for family in [egui::FontFamily::Proportional, egui::FontFamily::Monospace] {
        fonts.families.entry(family).or_default().push("korean".into());
    }
    ctx.set_fonts(fonts);
}

impl App {
    fn new(ctx: &egui::Context) -> Self {
        install_korean_font(ctx);
        // 실행 위치: apps/app-yjh-all-games-starter → 부모가 apps/
        let apps_dir = std::env::current_dir()
            .ok()
            .and_then(|d| {
                d.ancestors()
                    .find(|a| a.file_name().is_some_and(|n| n == "apps"))
                    .map(Path::to_path_buf)
            })
            .unwrap_or_else(|| PathBuf::from("."));
        Self {
            games: scan_games(&apps_dir),
            godot: find_godot(),
            apps_dir,
            running: Vec::new(),
            error: None,
        }
    }

    fn launch(&mut self, game_idx: usize, role: &'static str) {
        let Some(godot) = self.godot.clone() else {
            self.error = Some("Godot 실행 파일을 찾지 못했습니다".into());
            return;
        };
        let game = &self.games[game_idx];
        let mut cmd = Command::new(godot);
        if role == "서버" {
            cmd.arg("--headless");
        }
        cmd.arg("--path").arg(&game.project_dir);
        match cmd.spawn() {
            Ok(child) => {
                self.running.push(Running { game_id: game.id.clone(), role, child });
                self.error = None;
            }
            Err(e) => self.error = Some(format!("{}: 실행 실패 — {e}", game.id)),
        }
    }

    fn reap_finished(&mut self) {
        self.running
            .retain_mut(|r| matches!(r.child.try_wait(), Ok(None)));
    }

    fn running_count(&self, game_id: &str, role: &str) -> usize {
        self.running
            .iter()
            .filter(|r| r.game_id == game_id && r.role == role)
            .count()
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.reap_finished();
        ctx.request_repaint_after(std::time::Duration::from_secs(1));

        egui::TopBottomPanel::top("header").show(ctx, |ui| {
            ui.add_space(6.0);
            ui.heading("all-games-starter — 게임 바로 체험");
            ui.horizontal(|ui| {
                ui.label(format!("apps: {}", self.apps_dir.display()));
                ui.separator();
                match &self.godot {
                    Some(p) => ui.label(format!("godot: {}", p.display())),
                    None => ui.colored_label(egui::Color32::RED, "godot 미설치 — 실행 불가"),
                };
            });
            if let Some(err) = &self.error {
                ui.colored_label(egui::Color32::RED, err);
            }
            ui.add_space(6.0);
        });

        egui::TopBottomPanel::bottom("footer").show(ctx, |ui| {
            ui.add_space(4.0);
            ui.horizontal(|ui| {
                ui.label(format!("실행 중 {}개", self.running.len()));
                if !self.running.is_empty() && ui.button("전부 중지").clicked() {
                    for r in &mut self.running {
                        let _ = r.child.kill();
                    }
                }
            });
            ui.add_space(4.0);
        });

        egui::CentralPanel::default().show(ctx, |ui| {
            egui::ScrollArea::vertical().show(ui, |ui| {
                let mut actions: Vec<(usize, &'static str)> = Vec::new();
                // 접두사(game-{작성자})별 그룹 — 스캔 결과가 id 정렬이므로 순회하며 헤더만 갈아끼움
                let mut current_author: Option<&str> = None;
                for (i, game) in self.games.iter().enumerate() {
                    if current_author != Some(game.author.as_str()) {
                        current_author = Some(game.author.as_str());
                        let count = self.games.iter().filter(|g| g.author == game.author).count();
                        ui.add_space(8.0);
                        ui.heading(format!("game-{} · {}종", game.author, count));
                        ui.separator();
                    }
                    ui.group(|ui| {
                        ui.horizontal(|ui| {
                            ui.vertical(|ui| {
                                ui.strong(&game.id);
                                let kind = if game.is_multi { "멀티 (서버 권위)" } else { "싱글" };
                                ui.label(format!("작성자 {} · {}", game.author, kind));
                            });
                            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                                if game.is_multi {
                                    let servers = self.running_count(&game.id, "서버");
                                    let clients = self.running_count(&game.id, "클라");
                                    if ui.button(format!("클라 접속 ({clients})")).clicked() {
                                        actions.push((i, "클라"));
                                    }
                                    if ui.button(format!("서버 시작 ({servers})")).clicked() {
                                        actions.push((i, "서버"));
                                    }
                                } else {
                                    let n = self.running_count(&game.id, "플레이");
                                    if ui.button(format!("플레이 ({n})")).clicked() {
                                        actions.push((i, "플레이"));
                                    }
                                }
                            });
                        });
                    });
                    ui.add_space(4.0);
                }
                if self.games.is_empty() {
                    ui.label("apps/ 아래에서 game-* 디렉터리를 찾지 못했습니다.");
                }
                for (i, role) in actions {
                    self.launch(i, role);
                }
            });
        });
    }
}

impl Drop for App {
    fn drop(&mut self) {
        // 런처 종료 시 자식 게임 프로세스도 정리
        for r in &mut self.running {
            let _ = r.child.kill();
        }
    }
}

fn main() -> eframe::Result {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([760.0, 640.0]),
        ..Default::default()
    };
    eframe::run_native(
        "app-yjh-all-games-starter",
        options,
        Box::new(|cc| Ok(Box::new(App::new(&cc.egui_ctx)))),
    )
}
