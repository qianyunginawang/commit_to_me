# Tests

Run them all from the project folder:

```sh
godot --headless --path . --import             # only needed the first time
godot --headless --path . -s tests/run_tests.gd
```

(On a Mac, `godot` is `/Applications/Godot.app/Contents/MacOS/Godot`.)

- Every `test_*.gd` file here is picked up automatically.
- Each test file `extends TestCase` and has methods starting with `test_`.
- Use `check(condition, "message")` and `check_eq(actual, expected)`.
- `solutions/` has a working answer for every coding challenge. The tests make
  sure each answer passes **and** that the starter code doesn't pass on its own.
  When you add a challenge, add its solution here too (same name as the challenge id).
- Code-runner tests skip a language if it isn't installed on your computer.

GitHub runs these on every pull request (see `.github/workflows/tests.yml`).
