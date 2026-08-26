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

function toRel(fromFile, spec) {
  const cleaned = spec.replace(/\.js$/, "");
  const abs = path.resolve("dist", cleaned);
  let rel = path.relative(path.dirname(fromFile), abs);
  if (!rel.startsWith(".")) {
    rel = `./${rel}`;
  }
  return rel.replaceAll("\\", "/");
}

function rewrite(file) {
  const src = fs.readFileSync(file, "utf8");
  const next = src.replace(/require\(\s*(['"])@\/([^'"]+)\1\s*\)/g, (_m, _q, spec) => {
    return `require(${JSON.stringify(toRel(file, spec))})`;
  });
  if (next !== src) {
    fs.writeFileSync(file, next);
  }
}

walk("dist", rewrite);
