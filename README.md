# zero2prod

zero2prod rust examples

## Load `DATABASE_URL` from `configuration.toml`

```nu
let db = open configuration.toml | get database
$env.DATABASE_URL = $"postgres://($db | get username):($db | get password)@($db | get host):($db | get port)/($db | get database_name)"
echo $env.DATABASE_URL
```
