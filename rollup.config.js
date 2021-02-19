import resolve from "@rollup/plugin-node-resolve"
import sourcemaps from "rollup-plugin-sourcemaps"
import { terser } from "rollup-plugin-terser"
import pkg from "./package.json"

export default {
  input: pkg.module,
  output: {
    name: "ConstraintValidations",
    file: pkg.main,
    format: "iife",
    inlineDynamicImports: true,
    sourcemap: true
  },
  plugins: [
    sourcemaps(),
    resolve(),
    terser({
      mangle: false,
      compress: false,
      format: {
        beautify: true,
        indent_level: 2
      }
    })
  ]
}
