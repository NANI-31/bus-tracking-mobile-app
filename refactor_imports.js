const fs = require("fs");
const path = require("path");

function refactorImports(baseDir, aliasPrefix = "@/") {
  const files = getFiles(baseDir);
  let totalReplaced = 0;

  files.forEach((file) => {
    if (
      !file.endsWith(".ts") &&
      !file.endsWith(".js") &&
      !file.endsWith(".jsx") &&
      !file.endsWith(".tsx")
    )
      return;

    let content = fs.readFileSync(file, "utf8");
    const relativePath = path.relative(baseDir, file);
    const depth = relativePath.split(path.sep).length - 1;

    if (depth === 0) {
      // src/file.ts
      // Replace ./ with @/
      content = content.replace(/from ".\//g, `from "${aliasPrefix}`);
      content = content.replace(/from '.\//g, `from '${aliasPrefix}`);
    } else if (depth === 1) {
      // src/folder/file.ts
      // Replace ../ with @/
      content = content.replace(/from "..\//g, `from "${aliasPrefix}`);
      content = content.replace(/from '..\//g, `from '${aliasPrefix}`);
      // Also replace ./ if needed, but ./ usually stays local.
    } else if (depth === 2) {
      // src/folder/subfolder/file.ts
      // Replace ../../ with @/
      content = content.replace(/from "..\/\..\//g, `from "${aliasPrefix}`);
      content = content.replace(/from '..\/\..\//g, `from '${aliasPrefix}`);
      // Replace ../ with @/folder/
      // This is harder because we don't know the parent folder name easily here
      // But usually ../ in a depth 2 file goes to depth 1, which is still in src/
    }

    // Generic catch-all for deeper ones or specific patterns if needed
    // But the most common are ../ and ../../

    fs.writeFileSync(file, content);
  });
}

function getFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(getFiles(file));
    } else {
      results.push(file);
    }
  });
  return results;
}

const serverSrc = path.resolve(__dirname, "server/src");
const clientSrc = path.resolve(__dirname, "client/src");

console.log("Refactoring server imports...");
// For server, we want to replace relative imports which point to directories inside src
// The depth logic is a bit flawed because ../ in src/controllers/user.controller.ts points to src/
// but ../ in src/controllers/core/user.controller.ts points to src/controllers/
// Actually, it's safer to use a regex that matches ../ that goes OUT of the current directory but stays in src

function betterRefactor(baseDir) {
  const files = getFiles(baseDir);
  files.forEach((file) => {
    if (
      !file.endsWith(".ts") &&
      !file.endsWith(".js") &&
      !file.endsWith(".jsx") &&
      !file.endsWith(".tsx")
    )
      return;
    let content = fs.readFileSync(file, "utf8");

    // Match import ... from "../../..."
    // We want to replace the relative part that stays within src

    const fileDir = path.dirname(file);

    content = content.replace(
      /(import|export) (.*) from ["'](\.\.?\/.*)["']/g,
      (match, type, contentPart, importPath) => {
        const absoluteImportPath = path.resolve(fileDir, importPath);
        if (absoluteImportPath.startsWith(baseDir)) {
          const relativeToSrc = path
            .relative(baseDir, absoluteImportPath)
            .replace(/\\/g, "/");
          return `${type} ${contentPart} from "@/${relativeToSrc}"`;
        }
        return match;
      },
    );

    fs.writeFileSync(file, content);
  });
}

console.log("Refactoring server...");
betterRefactor(serverSrc);
console.log("Refactoring client...");
betterRefactor(clientSrc);
console.log("Done!");
