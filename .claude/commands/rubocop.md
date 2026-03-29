Run RuboCop on the Rails project to check and auto-correct style violations.

If the user specifies a file path, run RuboCop only on that file:
```
bin/rubocop -f github --autocorrect <file>
```

Otherwise, run it on the whole project:
```
bin/rubocop -f github --autocorrect
```

After running, report:
- Number of files inspected
- Number of offenses found (and how many were auto-corrected)
- Any remaining offenses that need manual attention, grouped by file
