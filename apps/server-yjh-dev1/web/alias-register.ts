import Module from "node:module";
import path from "node:path";

type Resolve = (
  request: string,
  parent: unknown,
  isMain: boolean,
  options?: unknown,
) => string;

const loader = Module as typeof Module & { _resolveFilename: Resolve };
const orig = loader._resolveFilename.bind(loader);
loader._resolveFilename = function resolveAlias(
  request: string,
  parent: unknown,
  isMain: boolean,
  options?: unknown,
): string {
  if (request.startsWith("@/")) {
    request = path.join(__dirname, request.slice(2));
  }
  return orig(request, parent, isMain, options);
};
