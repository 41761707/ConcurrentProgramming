with Ada.Text_IO;
with Ada.Containers.Vectors;
with ada.numerics.discrete_random;
with Ada.Strings.Bounded;
with Ada.Command_Line;
use Ada.Text_IO,Ada.Command_Line;

procedure zad2a is
	package integerVectors is new Ada.Containers.Vectors(Index_Type   => Natural,Element_Type => Integer);
	type randRange is new Integer range 1..5000;
   	package Rand_Int is new ada.numerics.discrete_random(randRange);
   	use Rand_Int;
   	gen : Generator;
   	type vertex is record
   		number:Integer;
   		next:integerVectors.Vector;
   		point:integerVectors.Vector;
   	end record;
   	type point is record
   		value:Integer;
   		visitedNodes:integerVectors.Vector;
   		ttl: Integer;
   	end record;
   	type pointPointer is access point;
   	type vertexPointer is access vertex;
   	package vertexVectors is new Ada.Containers.Vectors(Index_Type => Natural, Element_Type => vertexPointer);
   	package pointVectors is new Ada.Containers.Vectors(Index_Type => Natural, Element_Type => pointPointer);
 	Graph:vertexVectors.Vector;
 	Packet:pointVectors.Vector;
 	package SB is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 100);
    use SB;
    i:Integer:=1;
    firstArgument : SB.Bounded_String:=SB.To_Bounded_String(Argument(i));
    secondArgument : SB.Bounded_String:=SB.To_Bounded_String(Argument(i+1));
    thirdArgument : SB.Bounded_String:=SB.To_Bounded_String(Argument(i+2));
   	fourthArgument : SB.Bounded_String:=SB.To_Bounded_String(Argument(i+3));
    fifthArgument : SB.Bounded_String:=SB.To_Bounded_String(Argument(i+4));
   	n: Integer := Integer'Value (To_String (firstArgument));
   	d: Integer := Integer'Value (To_String (secondArgument));
   	b: Integer := Integer'Value (To_String (thirdArgument));
   	k: Integer := Integer'Value (To_String (fourthArgument));
   	h: Integer := Integer'Value (To_String (fifthArgument));
   	counterD:Integer:=0;
   	counterB:Integer:=0;
   	node:vertexPointer;
   	pakiet:pointPointer;
   	packetCounter: Integer:=0;
   	first: Integer;
   	second: Integer;
   	flag:Boolean;
   	
 		function Img (I : Integer) return String renames Integer'Image;
 		
   		procedure initNodes is
   			begin
   				for i in 0..n-1 loop
	   				node:= new vertex;
	   				node.number:=i;
	   				integerVectors.Append(node.next,Integer(i+1));
	   				vertexVectors.Append(Graph,node);
   				end loop;
   			end initNodes;
   		procedure shortcuts is
   			begin
   				Reset(gen);
   				while counterD<d loop
			   		flag :=false;
			   		first:=Integer(random(gen)) mod(n-2);
			   		second:=first+1+Integer(random(gen)) mod (n-2-first);  		
			   		for i of Graph(first).next loop
			   			if i = second then
			   				flag:=true;
			   				exit;
			   			end if;
			   		end loop;
			   		
			   		if(flag=false) then
			   			integerVectors.append(Graph.Element(first).next, second);
			   			counterD:=counterD+1;
			   		end if;
			   	end loop;
			   	while counterB<b loop
			   		flag :=false;
			   		second:=Integer(random(gen)) mod(n-2);
			   		first:=second+1+Integer(random(gen)) mod (n-2-second);  		
			   		for i of Graph(first).next loop
			   			if i = second then
			   				flag:=true;
			   				exit;
			   			end if;
			   		end loop;
			   		
			   		if(flag=false) then
			   			integerVectors.append(Graph.Element(first).next, second);
			   			counterB:=counterB+1;
			   		end if;
			   	end loop;
   			end shortcuts;
   		procedure displayGraph is
   			begin
   				Put_Line("Wierzcho????ek ------ Wierzcho????ki, z ktorymi istnieje krawedz");
   				for i of Graph loop
   					Ada.Text_IO.Put(i.number'Img & " ----- [");
   					for j of i.next loop
   						Ada.Text_IO.Put(j'Img & " ");
   						end loop;
   					Put_Line("]");	
   					end loop;
   			end displayGraph;
   			
   			
   		task type Printer is
   			entry startRunning;
   			entry print (text: in String);
   			entry put(text: in String);
   			--entry quit;
   		end Printer;
   			
   			
   		task type Listener (node:vertexPointer) is
   			entry StartRunning;
   			entry receive(value:in pointPointer);
   		end Listener;
   		
   		task type Receiver is
   			entry StartRunning;
   			entry receive(value: in pointPointer);
   			entry quit;
   		end Receiver;
   		taskReceiver:Receiver;
   		
   		type listenerPointer is access Listener;
   		type listenerArray is array (Integer range <>) of listenerPointer;
   		type listenerArrayPointer is access listenerArray;
   		Arr : listenerArray (0..n-1);
   		type printerPointer is access Printer;
   		printerFunc: Printer;
   		task type Sender is
   			entry startRunning;
   		end Sender;
   		task body Printer is
   		begin
   			loop
   				select
   					accept startRunning do
   						null;
   					end startRunning;
   					or
   					accept print(text:in String) do
   						Put_Line(text);
   					end print;
   					or
   					accept put(text:in String) do
						Ada.Text_IO.Put(text);
					end put;
   					or
	   					terminate;
   				end select;
   			end loop;
   		end Printer;
   		
   		
   		task body Sender is
   		begin
   			loop
   				select
		   			accept startRunning do
		   				null;
		   			end startRunning;
		   			Reset(gen);
		   			for i in 0 .. k-1 loop
		   				printerFunc.print("Sender wysyla pakiet: " & i'Img);
		   				Arr(0).receive(Packet(i));
		   				delay Duration(Float((Integer(random(gen)) mod 300)) / 1000.0); 
		   			end loop;
		   			exit;
		   		end select;
		   	end loop;
   		end Sender; 
   		
   		
   		procedure Raport is
   		begin
	   		printerFunc.print("Wierzcho????ek ----- punkty, kt????re go odwiedzi????y");
	   		for i of Graph loop
	   			printerFunc.put(i.number'Img & " ----- [");
	   			for j of i.point loop
	   				printerFunc.put(j'Img & " ");
	   			end loop;
	   			printerFunc.print("]");
	   		end loop;
	   		printerFunc.print("Punkty ------ Scie????ka wierzcho????k????w, po kt????rej podr????????owa????");
	   		for i of Packet loop
	   			printerFunc.put(i.value'Img & " ------ [");
	   			for j of i.visitedNodes loop
	   				printerFunc.put(j'Img & " ");
	   			end loop;
	   			printerFunc.print("]");
	   		end loop;
   		end Raport;
   		
   		task body Receiver is
   			packet: pointPointer;
   		begin
   			loop
   				select accept startRunning do
   					null;
   				end startRunning;
   				or
   				accept receive (value: in pointPointer) do
		   			packet:=value;
		   			packetCounter:=packetCounter+1;
		   		end receive;
	   				printerFunc.print("Pakiet " & packet.value'Img & " zostal odebrany ");
			   		if(packetCounter=k) then
			   			Raport;
			   			exit;
			   		end if;
			   	or
		   			accept quit do
		   				null;
		   			end quit;
		   			printerFunc.print("Receiver wychodzi");
		   			exit;
		   		or
		   			terminate;
		   		end select;
   			end loop;
   		end Receiver;
   		
   		
   		procedure forward(node : vertexPointer; packet : pointPointer) is
   			index: Integer:=0;
   			nextNode: Integer:=0;
   		begin
   			index:=Integer(random(gen)) mod Integer(node.next.length);
		   	nextNode:=node.next(index);	
		   	select 
		   		Arr(nextNode).receive(packet);
		   	or
		   		delay 0.1;
		   		forward(node,packet);
		   	end select;
   		end forward;
   		
   		
   		
   		task body Listener is
   			packet: pointPointer;
   			packetValue: Integer:=0;
   			index: Integer:=0;
   			nextNode: Integer:=0;
   		begin
   			loop
   				select
		   			accept startRunning do
		   				null;
		   			end startRunning;
		   			or
		   			accept receive (value: in pointPointer) do
		   				packet:=value;
		   			end receive;
		   				if packet.ttl=0 then
		   					printerFunc.print("Pakiet " & packet.value'Img & " zmarl w wierzcho????ku " & node.number'Img);
		   					for i of node.point loop
		   						if i = packet.value then
		   							goto Break_imitation_1;
		   						end if;
		   					end loop;
		   					IntegerVectors.Append(node.point,packet.value);
		   					<<Break_imitation_1>>
		   					IntegerVectors.Append(packet.visitedNodes,node.number);
		   					packetCounter:=packetCounter+1;
		   					if(packetCounter=k) then
		   						Raport;
		   						taskReceiver.quit;
		   						exit;
		   					end if;
		   				else
		   					Reset(gen);
		   					packet.ttl:=packet.ttl-1;
		   					printerFunc.print("Pakiet " & packet.value'Img & " jest w wierzcho????ku " & node.number'Img);
		   					--index:=Integer(random(gen)) mod Integer(node.next.length);
		   					--nextNode:=node.next(index);	
		   					for i of node.point loop
		   						if i = packet.value then
		   							goto Break_imitation_2;
		   						end if;
		   					end loop;
		   					IntegerVectors.Append(node.point,packet.value);
		   					<<Break_imitation_2>>
		   					IntegerVectors.Append(packet.visitedNodes,node.number);
		   					if(node.number /= n-1) then
		   						--Arr(nextNode).receive(packet);
		   						forward(node,packet);
		   					else
		   						taskReceiver.receive(packet);
		   					end if;
		   				end if;
		   				delay Duration(Float((Integer(random(gen)) mod 300)) / 1000.0);
		   			or
		   				terminate;
		   		end select;
		   	end loop;
   		end Listener;
   		
   		
	begin
	if(d>((n-3)*n)/2) then
   		Put_Line("Za du????o skr????t????w");
   		--goto Exit_Use_Goto;
   		return;
   	end if;
   	if(b>(((n-3)*n)/2)) then
   		Put_Line("Za du????o skr????t????w");
   		return;
   	end if;
   	initNodes;
   	shortcuts;
   	displayGraph;
   	declare
   		taskSender:Sender;
   		begin
   		for i in 0..k-1 loop
   			pakiet:=new point;
   			pakiet.value:=i;
   			pakiet.ttl:=h;
   			pointVectors.append(Packet,pakiet);
   		end loop;
   		for j in 0..n-1 loop
   			Arr(j) :=new Listener (node => Graph(j));
   		end loop;
   		printerFunc.startRunning;
   		taskReceiver.startRunning;
   		for i in 0..n-1 loop
   			Arr(i).startRunning;
   		end loop;
   		taskSender.startRunning;
   	end;
	end zad2a;