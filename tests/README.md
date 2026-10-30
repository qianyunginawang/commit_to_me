# Tests

Run them all from the project folder:

```sh
godot --headless --path . --import             # only needed the first time
godot --headless --path . -s tests/run_tests.gd
```

(On a Mac, `godot` is `/Applications/Godot.app/Contents/MacOS/Godot`.)

- Every `test_*.gd` file here is picked up automatically. A file that doesn't compile, or has no `test_` methods, counts as a failure.
- Each test file `extends TestCase` and has methods starting with `test_`.
- Use `check(condition, "message")` and `check_eq(actual, expected)`.
- `solutions/` has a working answer for every coding challenge. The tests make
  sure each answer passes **and** that the starter code doesn't pass on its own.
  When you add a challenge, add its solution here too (same name as the challenge id).
- Code-runner tests skip a language if it isn't bundled (`python3 tools/fetch_runtimes.py`)
  or installed on your computer. Set `CTM_REQUIRE_BUNDLED=1` to also check that
  every language uses the bundled copy (GitHub does this).

GitHub runs these on every pull request (see `.github/workflows/tests.yml`).
