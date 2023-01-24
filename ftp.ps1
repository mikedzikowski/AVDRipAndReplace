
# Function to get directory listing
Function Get-FTPFileList {

    Param (
     [System.Uri]$server,
     [string]$directory
    )
    try
     {
        #Create URI by joining server name and directory path
        $uri =  "$server"
        #Create an instance of FtpWebRequest
        $FTPRequest = [System.Net.FtpWebRequest]::Create($uri)
        #Set anon auth
        $FTPRequest.Credentials = New-Object System.Net.NetworkCredential("anonymous",(New-Object System.Security.SecureString))

        $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
        #Get FTP response
        $FTPResponse = $FTPRequest.GetResponse()

        #Get Reponse data stream
        $ResponseStream = $FTPResponse.GetResponseStream()

        #Read data Stream
        $StreamReader = New-Object System.IO.StreamReader $ResponseStream

        #Read each line of the stream and add it to an array list
        $files = New-Object System.Collections.ArrayList
        foreach($f in $StreamReader.ReadLine())
         {
           [void] $files.add("$file")
        }
    }
    catch {
        #Show error message if any
        write-host -message $_.Exception.InnerException.Message
    }
        #Close the stream and response
        $StreamReader.close()
        $ResponseStream.close()
        $FTPResponse.Close()
        Return $files
    }
    #Set server name, user, password and directory
    $server = 'ftp://ftp.matrixgames.com/pub'
    #Function call to get directory listing
    $filelist = Get-FTPFileList -server $server
    #Write output
    Write-Output $filelist

