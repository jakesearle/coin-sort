# coin-sort

Run with:

`pico8 -run ./cart.p8`

Build with

`lua build.lua`

Test build with

`pico8 -run ./build.p8`

## Style guide

* Private methods and variables begin with `_`
  * Use this regex to check:
  * `(?<!function\s)\b(?!self\b)\w+:_`
* Method prefixes
  * `get_` / `is_` means the operation is quick and stateless
  * `set_` means the operation is quick and state-ful
  * `calc_` means the operation is slow-ish and state-ful
