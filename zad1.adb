with Ada.Text_IO;
with Ada.Containers.Vectors;
with ada.numerics.discrete_random;
with Ada.Strings.Bounded;
with Ada.Command_Line;
use Ada.Text_IO,Ada.Command_Line;

procedure zad1 is
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
   	n: Integer := Integer'Value (To_String (firstArgument));
   	d: Integer := Integer'Value (To_String (secondArgument));
   	k: Integer := Integer'Value (To_String (thirdArgument));
   	counter:Integer:=0;
   	node:vertexPointer;
   	pakiet:pointPointer;
   	first: Integer;
   	second: Integer;
   	flag:Boolean;
   	
 		function Img (I : Integer) return String renames Integer'Image;
 		
   		procedure initNodes is
   			begin
   				for i in 0..n-1 loop
	   				node:= new vertex;
	   				node.number:=i;
	   				if(i/=n-1) then
	   					integerVectors.Append(node.next,Integer(i+1));
	   				end if;
	   				vertexVectors.Append(Graph,node);
   				end loop;
   			end initNodes;
   		procedure shortcuts is
   			begin
   				while counter<d loop
   					Reset(gen);
			   		flag :=false;
			   		first:=Integer(random(gen)) mod(n-2);
			   		second:=first+1+Integer(random(gen)) mod (n-2-first);  		
			   		for i in Graph.Element(first).next.First_Index .. Graph.Element(first).next.Last_Index loop
			   			if Graph.Element(first).next.Element(i) = second then
			   				flag:=true;
			   				exit;
			   			end if;
			   		end loop;
			   		
			   		if(flag=false) then
			   			integerVectors.append(Graph.Element(first).next, second);
			   			counter:=counter+1;
			   		end if;
			   	end loop;
   			end shortcuts;
   		procedure displayGraph is
   			begin
   				Put_Line("WierzchoĹek ------> WierzchoĹek");
   				Put_Line(" strzaĹka symbolizuje krawÄdĹş skierowanÄ");
   				for i in Graph.First_Index .. Graph.Last_Index loop
   					for j in Graph.Element(i).next.First_Index .. Graph.Element(i).next.Last_Index loop
   						Put_Line(Graph.Element(i).number'Img & "-------->" & Graph.Element(i).next.Element(j)'Img);
   							end loop;
   						end loop;
   			end displayGraph;
   		task type Printer is
   			entry startRunning;
   			entry print (text: in String);
   			--entry quit;
   		end Printer;
   			
   			
   		task type Listener (node:vertexPointer) is
   			entry StartRunning;
   			entry receive(value:in pointPointer);
   			--entry quit;
   		end Listener;
   		
   		
   		type listenerPointer is access Listener;
   		type listenerArray is array (Integer range <>) of listenerPointer;
   		type listenerArrayPointer is access listenerArray;
   		Arr : listenerArray (1..n-1);
   		type printerPointer is access Printer;
   		printerFunc: Printer;
   		task type Sender (node:vertexPointer) is
   			entry startRunning;
   		end Sender;
   		type senderPointer is access Sender;
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
	   					terminate;
   				end select;
   			end loop;
   		end Printer;
   		
   		
   		task body Sender is
   			index: Integer:=0;
   			nextNode: Integer:=0;
   		begin
   			loop
   				select
		   			accept startRunning do
		   				null;
		   			end startRunning;
		   			Reset(gen);
		   			for i in 0 .. k-1 loop
		   				printerFunc.print("Sender wysyla pakiet: " & i'Img);
		   				index:=Integer(random(gen)) mod Integer(node.next.length);
		   				nextNode:=node.next(index);
		   				IntegerVectors.Append(node.point,i);
		   				IntegerVectors.Append(Packet(i).visitedNodes,node.number);
		   				Arr(nextNode).receive(Packet(i));
		   				delay Duration(Float((Integer(random(gen)) mod 300)) / 1000.0); 
		   			end loop;
		   			exit;
		   		end select;
		   	end loop;
   		end Sender; 
   		
   		procedure Raport is
   		begin
	   		printerFunc.print("WierzchoĹek ----- punkt, ktĂłry go odwiedziĹ");
	   		for i of Graph loop
	   			for j of i.point loop
	   				printerFunc.print(i.number'Img & " ----- " & j'Img);
	   			end loop;
	   		end loop;
	   		printerFunc.print("Punkty ------ wierzchoĹek, ktĂłry odwiedziĹ");
	   		for i of Packet loop
	   			for j of i.visitedNodes loop
	   				printerFunc.print(i.value'Img & " ------ " &j'Img);
	   			end loop;
	   		end loop;
   		end Raport;
   		
   		task body Listener is
   			packet: pointPointer;
   			packetValue: Integer:=0;
   			index: Integer:=0;
   			nextNode: Integer:=0;
   			packetCounter: Integer:=0;
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
		   				if(node.number=n-1) then
		   					printerFunc.print("Pakiet " & packet.value'Img & " zostaĹ odebrany");
		   					packetCounter:=packetCounter+1;
		   				else
		   					printerFunc.print("Pakiet " & packet.value'Img & " jest w wierzchoĹku " & node.number'Img);
		   					index:=Integer(random(gen)) mod Integer(node.next.length);
		   					nextNode:=node.next(index);
		   					
		   				end if;	
		   				IntegerVectors.Append(node.point,packet.value);
		   				IntegerVectors.Append(packet.visitedNodes,node.number);
		   				delay Duration(Float((Integer(random(gen)) mod 300)) / 1000.0);
		   			if(node.number /= n-1) then
		   				Arr(nextNode).receive(packet);
		   			else
		   				if(packetCounter=k) then
		   					--for i in 1..n-2 loop
		   						--Arr(i).quit;
		   					--end loop;
		   					Raport;
		   					exit;
		   				end if;
		   			end if;
		   			or
		   				terminate;
		   		end select;
		   	end loop;
   		end Listener;
   		
	begin
   	initNodes;
   	shortcuts;
   	displayGraph;
   	declare
   		taskSender:Sender(Graph (0));
   		begin
   		for i in 0..k-1 loop
   			pakiet:=new point;
   			pakiet.value:=i;
   			pointVectors.append(Packet,pakiet);
   		end loop;
   		for j in 1..n-1 loop
   			Arr(j) :=new Listener (node => Graph(j));
   		end loop;
   		printerFunc.startRunning;
   		for i in 1..n-1 loop
   			Arr(i).startRunning;
   		end loop;
   		taskSender.startRunning;
   		--taskSender.quit;
   	end;
	end zad1;