# Test script for the Logic App
$body = Get-Content "test-request.json" -Raw

# Try to find the correct local endpoint
Write-Host "Testing Logic App with valid data..."

try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/UpsertEmployee/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Success! Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "Error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host "Response content:" -ForegroundColor Yellow
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = [System.IO.StreamReader]::new($stream)
        Write-Host $reader.ReadToEnd()
        $reader.Close()
        $stream.Close()
    }
}