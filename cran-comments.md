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
- `load_database()` writes nothing to the working directory unasked. With `path = NULL` (the default) it keeps downloaded databases in `tools::R_user_dir("traits.use", which = "cache")`, as the policy allows, so each release is downloaded once per computer rather than once per project. The cache is managed by `list_cached_databases()` (size and last use of each database), `clear_database_cache()` (deletes all, named, or not-used-for-`older_than`-days databases), and a message after each download into the cache naming the other databases there with their size and last use.
- No example or test writes to that cache: examples only read it, and the tests set the `traits.use.cache_dir` option to a `tempfile()` path. The tests run on CRAN write only to `tempfile()` paths.
