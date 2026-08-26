import fs from "fs";
import path from "path";

function walk(dir, visit) {
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    if (fs.statSync(full).isDirectory()) {
      walk(full, visit);
      continue;
    }
    if (full.endsWith(".js")) {
      visit(full);
    }
  }
}

function rewrite(file) {
  const src = fs.readFileSync(file, "utf8");
  const next = src.replace(/require\((['"])@\/([^'"]+)\1\)/g, (_m, _q, spec) => {
    const abs = path.resolve("dist", spec);
    let rel = path.relative(path.dirname(file), abs);
    if (!rel.startsWith(".")) {
      rel = `./${rel}`;
    }
    return `require(${JSON.stringify(rel)})`;
  });
  if (next !== src) {
    fs.writeFileSync(file, next);
  }
}

walk("dist", rewrite);
