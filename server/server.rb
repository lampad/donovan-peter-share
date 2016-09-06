require "socket"
require "io/wait"
require "base64"
Thread::abort_on_exception=true
server = TCPServer.new 2000
debug=true
$sfiles={}
$users={}
$status=[]
$pass=[]
$umod_time=nil
$smod_time=nil
def read_users()
  if $umod_time!=File.mtime("users.txt")
    lines=File.readlines("users.txt")
    i=0
    lines.each do |line|
      if line[0]!="#"
        line=line.chomp.split(",")
        $users[line[0]]=i
        $status[i]=line[1]
        $pass[i]=line[2]
        i=i+1
      end  
    end
    $umod_time=File.mtime("users.txt")
  end
  puts $pass.inspect 
end

def read_sfiles()
  if $smod_time!=File.mtime("secure.txt")
    lines=File.readlines("secure.txt")
    lines.each do |line|
     line=line.chomp.split(",")
     $sfiles["./"+line[0]]=line[1]
    end
    $smod_time=File.mtime("secure.txt")
  end
end

def get_data(client)
  lines=[]
  line=client.gets
  while line !="\r\n"
    lines<<line
    line=client.gets
  end
  i=0
  lines.each do |value|
    lines[i]=value.chomp
    i=i+1
  end
  temp=lines.shift
  method=temp.split(" ")[0]
  url=temp.split(" ")[1]
  headers={}
  lines.each do |value|
    temp=value.split(": ")
    headers[temp[0]]=temp[1]
  end
  body=[]
  while client.ready?
    body<<client.gets.chomp
  end
  return {"lines"=>lines,"headers"=>headers,"url"=>url,"method"=>method,"body"=>body}
end

def send_response(status,headers,body,client,url,debug)
  if debug
    puts status
  else
    if status.split(" ")[0]=="404"
      puts "Could not find file #{url}"
    end
  end
  header=""
  headers.each do |key,value|
    header+="#{key}: #{value}\n"
  end
  client.puts "HTTP/1.1 #{status}\n#{header}\n#{body}"
  client.close
end

def procces_req(url,headers,good,bad,nou,noa,notf)
  if File.exist?(url)
    if headers["Authorization"]
      auth=headers["Authorization"].split(" ")[1]
      auth=Base64.decode64(auth).split(":")
      user=auth[0]
      pass=auth[1]
      auth=[user,pass]
      if $users.has_key? user
        if $pass[$users[user]]==pass
          good.call($status[$users[user]])
        else
          bad.call
        end
      else
        nou.call  
      end  
    else
      auth="No auth"
      noa.call
      return
    end
  else
    notf.call
  end
end

def type(url)
  case File.extname(url)
  when ".html"
    return "text/html"
  when ".txt"
    return "text/plain"
  when ".css"
    return "text/css"
  when ".js"
    return "application/javascript"
  when ".jpg",".jpeg"
    return "image/jpg"
  when ".png"
    return "image/png"
  when ".mp3"
    return "audio/mpeg"
  when ".ogg"
    return "audio/ogg"
  when ".mp4"
    return "video/mp4"
  when ".webm"
    return "video/webm"
  else
    return "text/html"
  end
end

def fix(url)
  case File.extname(url)
  when ".html"
    return url
  when ".txt"
    return url
  when ".css"
    return url
  when ".js"
    return url
  when ".jpg",".jpeg"
    return url
  when ".png"
    return url
  when ".mp3"
    return url
  when ".ogg"
    return url
  when ".mp4"
    return url
  when ".webm"
    return url
  else
    return url+".html"
  end
end
def secure(url)
  read_sfiles()
  if $sfiles.include? url
    return true
  else
    return false
  end
end

def uok(url,level)
  read_sfiles()
  if $sfiles.include? url
    if $sfiles[url]==level or ($sfiles[url]=="normal" and level=="admin")
      return true
    else
      return false
    end
  else
    return true
  end
end

def sfile(file,headers,type,client,url,debug)
  total=file.length
  range=headers["Range"]
  positions=range.split("=")[1].split("-")
  start=positions[0].to_i(10)
  m_end=positions[1] ? positions[1].to_i(10) : total - 1;
  chunksize=(m_end-start)+1
  chunk=file[start, m_end+1]
  if type=="mp4"
    r_headers={"Content-Range"=>"bytes #{start}-#{m_end}/#{total}","Accept-Ranges"=>"bytes","Content-Length"=>chunksize,"Content-Type"=>"video/mp4"}
  elsif type=="webm"
    r_headers={"Content-Range"=>"bytes #{start}-#{m_end}/#{total}","Accept-Ranges"=>"bytes","Content-Length"=>chunksize,"Content-Type"=>"video/webm"}
  elsif type=="mpeg"
    r_headers={"Content-Range"=>"bytes #{start}-#{m_end}/#{total}","Accept-Ranges"=>"bytes","Content-Length"=>chunksize,"Content-Type"=>"audio/mpeg"}
  elsif type=="ogg"
    r_headers={"Content-Range"=>"bytes #{start}-#{m_end}/#{total}","Accept-Ranges"=>"bytes","Content-Length"=>chunksize,"Content-Type"=>"audio/ogg"}
  end
  return send_response("206 Partial Content",r_headers,chunk,client,url,debug)
end
puts "Server running on localhost:2000"
loop do
  Thread.start(server.accept) do |client|
    begin
      read_users()
      temp=get_data(client)
      lines=temp["lines"]
      headers=temp["headers"]
      method=temp["method"]
      url=temp["url"]
      url="."+url
      if url=="./"
        url="./index.html"
      end
      url=fix(url)
      body=temp["body"]
      url=url.gsub("%20"," ")
      if debug
        puts "#{method} #{url}"
      end
      procces_req(url,headers,lambda { |level|
          if uok(url,level)
            if type(url)=="video/mp4"
              sfile(File.open(url, "rb") {|io| io.read},headers,"mp4",client,url,debug)
            elsif type(url)=="video/webm"
              sfile(File.open(url, "rb") {|io| io.read},headers,"webm",client,url,debug)
            elsif type(url)=="audio/mpeg"
              sfile(File.open(url, "rb") {|io| io.read},headers,"mpeg",client,url,debug)
            elsif type(url)=="audio/ogg"
              sfile(File.open(url, "rb") {|io| io.read},headers,"ogg",client,url,debug)
            else
              send_response("200 OK",{"Content-Type"=>type(url)},File.read(url),client,url,debug)
            end
          else
            send_response("401 Unauthorized",{"WWW-Authenticate"=>"Basic realm=''","Content-Type"=>"text/html"},File.read("./empty.html"),client,url,debug)\
          end
      },lambda {
          #Bad Auth
          send_response("401 Unauthorized",{"WWW-Authenticate"=>"Basic realm=''","Content-Type"=>"text/html"},File.read("./empty.html"),client,url,debug)  
      },lambda {
          #No User
          send_response("401 Unauthorized",{"WWW-Authenticate"=>"Basic realm=''","Content-Type"=>"text/html"},File.read("./empty.html"),client,url,debug)
      },lambda {
          #No Auth
          if secure(url)
            send_response("401 Unauthorized",{"WWW-Authenticate"=>"Basic realm=''","Content-Type"=>"text/html"},File.read("./empty.html"),client,url,debug)
          else
            if type(url)=="video/mp4"
              sfile(File.open(url, "rb") {|io| io.read},headers,"mp4",client,url,debug)
            elsif type(url)=="video/webm"
              sfile(File.open(url, "rb") {|io| io.read},headers,"webm",client,url,debug)
            elsif type(url)=="audio/mpeg"
              sfile(File.open(url, "rb") {|io| io.read},headers,"mpeg",client,url,debug)
            elsif type(url)=="audio/ogg"
              sfile(File.open(url, "rb") {|io| io.read},headers,"ogg",client,url,debug)
            else
              send_response("200 OK",{"Content-Type"=>type(url)},File.read(url),client,url,debug)
            end
          end
      }, lambda {
        #Not Found
        send_response("404 Not Found",{"Content-Type"=>"text/html"},File.read("./empty.html"),client,url,debug) 
      })
    rescue Exception=>e
      puts e
      puts e.backtrace
    end
  end
end