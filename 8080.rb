require "drb/drb"
class CPU
	def initialize()
		@a=0
		@b=0
		@c=0
		@d=0
		@e=0
		@h=0
		@l=0
		@zf=0
		@cf=0
		@pc=0
		@sp=0
		@mem=Array.new(65536,0)
		@memmlist=[]
		@io=Array.new(255,0)
	end

	def gline(path, line)
	  result = nil

	  File.open(path, "r") do |f|
	    while line > 0
	      line -= 1
	      result = f.gets
	    end
	  end

	  return result
	end
	
	def execute(op)
		string=""
		command=op.split(" ")[0]
		if op.split(" ").length > 1
			operands=op.split(" ")[1].split(",")
			i=0
		end
		jmpop=false
		case command.upcase
			when "EXIT"
				return
			when "MONIT"
				memmlist=[]
				operands.each do |adr|
					memmlist.push(adr.to_i)
				end
		  when "STA"
		  	@mem[operands[0].to_i]=@a
		  when "LDA"
		  	@a=@mem[operands[0].to_i]
			when "MVI"
				operands[1]=operands[1].to_i
				case operands[0]
					when "a"
						@a=operands[1]
					when "B"
						@b=operands[1]
					when "C"
						@c=operands[1]
					when "D"
						@d=operands[1]
					when "E"
						@e=operands[1]
					when "H"
						@h=operands[1]
					when "L"
						@l=operands[1]
				end
			when "ADD"
				@zf=0
				@cf=0
				case operands[0]
						when "B"
							@a=@a+@b
						when "C"
							@a=@a+@c
						when "D"
							@a=@a+@d
						when "E"
							@a=@a+@e
						when "H"
							@a=@a+@h
						when "L"
							@a=@a+@h
					end
				if @a==0
					@zf=1
				end
				if @a>=256
					@cf=1
					@a=0
				end
			when "INR"
				case operands[0]
						when "A"
							@a=@a+1
						when "B"
							@b=@b+1
						when "C"
							@c=@c+1
						when "D"
							@d=@d+1
						when "E"
							@e=@e+1
						when "H"
							@h=@h+1
						when "L"
							@l=@l+1
					end
			when "DCR"
				case operands[0]
						when "a"
							@a=@a-1
						when "B"
							@b=@b-1
						when "C"
							@c=@c-1
						when "D"
							@d=@d-1
						when "E"
							@e=@e-1
						when "H"
							@h=@h-1
						when "L"
							@l=@l-1
					end
			when "MOV"
				instance_variable_set("@"+operands[0].downcase,instance_variable_get("@"+operands[1].downcase))
			when "OUT"
				@io[operands[0].to_i]=@a
			when "IN"
				@a=@io[operands[0].to_i]
			when "JMP"
				jmpop=true
				@pc=operands[0].to_i
		end
		unless jmpop
			@pc=@pc+1
		end
		jmpop=false
		i=0
		pr=0
		string+="A:#{@a}, B:#{@b}, C:#{@c}, D:#{@d}, E:#{@e}, H:#{@h}, L:#{@l}, PC:#{@pc}, SP:#{@sp}, ZF:#{@zf}, CF:#{@cf}"
		@memmlist.each do |adr|
			if pr==4
				string+="\n"
				pr=0
			end
			if i<@memmlist.length-1
				string+="mem[#{adr}]=#{mem[adr]}, "
			else
				string+="mem[#{adr}]=#{mem[adr]}"
			end
			i=i+1
			pr=pr+1
		end
		if @memmlist.length>0
			string+="\n"
		end
		return string
	end
	
	def pc()
		return @pc
	end
	
	def set_io(port,val)
		@io[port]=val
	end
	
	def get_io(port)
		return @io[port]
	end
	
	def reset()
		@a=0
		@b=0
		@c=0
		@d=0
		@e=0
		@h=0
		@l=0
		@zf=0
		@cf=0
		@pc=0
		@sp=0
	end
end
cpu=CPU.new()
def startDRb(port,obj)
	DRb.start_service("druby://localhost:"+port.to_s, obj)	
end
startDRb(1024,cpu)
while true
	case cpu.pc
		when 0
			#cpu.set_io(0,gets.chomp!.to_i)
			puts cpu.execute("IN 0")
		when 1
			puts cpu.execute("MOV B,A")
	  when 2
			#cpu.set_io(1,gets.chomp!.to_i)
			puts cpu.execute("IN 1")
		when 3
			puts cpu.execute("ADD B")
		when 4
			puts cpu.execute("OUT 2")
			#puts cpu.get_io(2)
		when 5
			puts cpu.execute("JMP 0")
	end
end