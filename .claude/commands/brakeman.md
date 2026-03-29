Run Brakeman security scan on the Rails project to detect security vulnerabilities.

Execute:
```
bin/brakeman --no-pager -f text
```

After running, report:
- Total warnings found
- Each warning with: severity (High/Medium/Low), type of vulnerability, affected file and line, and a brief explanation
- Prioritize High severity warnings first
- If no warnings found, confirm the scan passed cleanly
