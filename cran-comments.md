## Submission

This is a new submission. traits.use loads and wrangles trait databases built with the 'traits.build' workflow, such as AusTraits (<doi:10.1038/s41597-021-01006-6>). Its code and history come from the 'austraits' package on GitHub (never on CRAN), which becomes a thin AusTraits-specific layer over traits.use.

## Test environments

- local macOS (aarch64), R 4.6.1
- GitHub Actions: macOS-latest and windows-latest, R release
- win-builder: R-devel (to do)

## R CMD check results

0 errors | 0 warnings | 1 note

- New submission.

## Notes for reviewers

- Tests that download databases from Zenodo or Figshare are skipped on CRAN (`skip_on_cran()`, `skip_if_offline()`).
- `load_database()` downloads a database only to the `path` the user gives; `path` has no default. The tests run on CRAN write only to `tempfile()` paths.
