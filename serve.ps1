$port = 3334
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$port"

while ($listener.IsListening) {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $res  = $ctx.Response
    $path = $req.Url.LocalPath

    if ($path -eq "/" -or $path -eq "") { $path = "/index.html" }
    $rel  = [System.Uri]::UnescapeDataString($path).TrimStart('/')
    $file = [System.IO.Path]::Combine($root, $rel)

    Write-Host "$($req.HttpMethod) $path"

    if ([System.IO.File]::Exists($file)) {
        $ext  = [System.IO.Path]::GetExtension($file).ToLower()
        $mime = switch ($ext) {
            ".html" { "text/html; charset=utf-8" }
            ".js"   { "application/javascript; charset=utf-8" }
            ".css"  { "text/css; charset=utf-8" }
            ".json" { "application/json; charset=utf-8" }
            ".png"  { "image/png" }
            ".svg"  { "image/svg+xml" }
            default { "application/octet-stream" }
        }
        $res.ContentType     = $mime
        $res.StatusCode      = 200
        $bytes               = [System.IO.File]::ReadAllBytes($file)
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $res.StatusCode = 404
        Write-Host "  -> 404"
    }
    $res.OutputStream.Close()
}
