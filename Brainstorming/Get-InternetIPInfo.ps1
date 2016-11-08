# Get IPs from pcap - "tshark.exe -r file.cap -T fields -e ip.dst -e ip.src > output.txt"
# This script just takes a list of ips and checks the owner and ip blocks they are associated with
# Note: just update the file name, and consider using runspace for threading, its super slow

# Create data table for output
$mytable = new-object System.Data.DataTable
$mytable.Columns.Add("IpAddress") | Out-Null
$mytable.Columns.Add("Owner") | Out-Null
$mytable.Columns.Add("StartRange") | Out-Null
$mytable.Columns.Add("EndRange") | Out-Null
$mytable.Columns.Add("Country") | Out-Null
$mytable.Columns.Add("City") | Out-Null
$mytable.Columns.Add("Zip") | Out-Null
$mytable.Columns.Add("ISP") | Out-Null

# Load the list of ips
$arinip = gc iplist.txt

# Interate through each IP
$arinip | ForEach-Object {

    $IpAddress = $_

    # Send whois request to arin via restful api
    $web = new-object system.net.webclient
    [xml]$results = $web.DownloadString("http://whois.arin.net/rest/ip/$IpAddress")

    # Send location query to http://ip-api.com via xml api
    $web2 = new-object system.net.webclient
    [xml]$results2 = $web2.DownloadString("http://ip-api.com/xml/$IpAddress")

    # Parse data from responses    
    $IpOwner = $results.net.name 
    $IpStart = $results.net.startAddress
    $IpEnd = $results.net.endaddress  
    $IpCountry = $results2.query.country.'#cdata-section'
    $IpCity = $results2.query.city.'#cdata-section'
    $IpZip = $results2.query.zip.'#cdata-section'
    $IpISP = $results2.query.isp.'#cdata-section'
    
    # Put results in the data table   
    $mytable.Rows.Add("$IpAddress",
                      "$IpOwner",
                      "$IpStart",
                      "$IpEnd",
                      "$IpCountry",
                      "$IpCity",
                      "$IpZip",
                      "$IpISP") | Out-Null

    # status the user
    Write-Host "Name: $IpOwner ($IpCountry) - $IpAddress - ($IpStart -$IpEnd)"
    
}

# Return the full result set
$mytable | Sort-Object Owner -Unique

