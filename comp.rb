$tape=nil

def tape_read(char)
  $tape.rewind()
  return $tape.read.split("\n")[char]
end

def tape_write(char,data,content=[])
  $tape.rewind
  #How do we fix this?
  if content.empty?
    current_content_array = $tape.read.split("\n")
  else
    current_content_array = content
  end
  $tape.rewind
  current_content_array[char] = data
  current_content_array.compact!
  current_content_array.each do |character|
    $tape.puts(character)
  end
end

def tape_insert(name)
  current_content = []
  if File.exists?(name+".tap")
    current_content = File.read(name+".tap").split("\n")
  end

  $tape = File.open(name+".tap","w+")
  return current_content
end

def tape_eject()
  $tape.close()
  $tape=nil
end

i=0
content = tape_insert("test")
tape_write(i,"a",content)
i=1
tape_write(i,"~",content)
tape_eject()
content = tape_insert("test")
tape_write(i,"t",content)
i=2
tape_write(i,"~",content)
tape_eject