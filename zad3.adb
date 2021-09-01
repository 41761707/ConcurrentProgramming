with Ada.Text_IO;
with Ada.Containers.Vectors;
with ada.numerics.discrete_random;
with Ada.Strings.Bounded;
with Ada.Command_Line;
use Ada.Text_IO,Ada.Command_Line;

procedure zad3 is

	package integerVectors is new Ada.Containers.Vectors(Index_Type =>Natural, Element_Type=>Integer);
	type randRange is new Integer range 1..5000;
	package Rand_Int is new ada.numerics.discrete_random(randRange);
	use Rand_Int;
	gen : Generator;
	
	type routing is record
		sender: Integer;
		number: Integer;
		nextHop: Integer;
		cost: Integer;
		changed: Boolean;
	end record;
	type routingPointer is access routing;
	
	package routingVectors is new Ada.Containers.Vectors(Index_Type => Natural, Element_Type => routingPointer); 
	type vertex is record
		number: Integer;
		next  : integerVectors.Vector;
		routing : routingVectors.Vector;
	end record;	
	type vertexPointer is access vertex;
	package vertexVectors is new Ada.Containers.Vectors(Index_Type => Natural, Element_Type => vertexPointer);
	
	Graph: vertexVectors.Vector;
	package SB is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 100);
	use SB;
	i:Integer:=1;
	firstArgument: SB.Bounded_String:=SB.To_Bounded_String(Argument(i));
	secondArgument: SB.Bounded_String:=SB.To_Bounded_String(Argument(i+1));
	n:Integer:=Integer'Value (To_String(firstArgument));
	d:Integer:=Integer'Value (To_String(secondArgument));
	counterD:Integer:=0;
	currentNode:vertexPointer;
	currentRouting:routingPointer;
	first:Integer;
	second:Integer;
	flag:Boolean;
	reportCounter:Integer:=0;
	
	protected type Mutex is
   		entry Seize;
   		procedure Release;
	private
   		Owned : Boolean := False;
	end Mutex;
	
	protected body Mutex is
   		entry Seize when not Owned is
   		begin
    	  	Owned := True;
   		end Seize;
   		procedure Release is
   		begin
      		Owned := False;
   		end Release;
	end Mutex;
	
	
	function Img(I:Integer) return String renames Integer'Image;
	
	procedure initNodes is
		begin
			for i in 0..n-1 loop
				currentNode:=new vertex;
				currentNode.number:=i;
				if(i/=n-1) then
					integerVectors.Append(currentNode.next,Integer(i+1));
				end if;
				if(i/=0) then
					integerVectors.Append(currentNode.next,Integer(i-1));
				end if;
				vertexVectors.Append(Graph,currentNode);
			end loop;
		end initNodes;
	procedure shortcuts is
		begin
			Reset(gen);
			while counterD<d loop
				flag:=false;
				first:=Integer(random(gen)) mod(n-2);
				second:=first+1+Integer(random(gen)) mod (n-2-first);
				for i of Graph(first).next loop
					if i=second then
						flag:=true;
						exit;
					end if;
				end loop;
					
				if(flag=false) then
				integerVectors.Append(Graph.Element(first).next,second);
				integerVectors.Append(Graph.Element(second).next,first);
				counterD:=counterD+1;
				end if;
			end loop;
		end shortcuts;
	procedure displayGraph is
		begin
			Put_Line("Wierzcholek <---> Lista wierzchoĹkĂłw, z ktĂłrÄ istnieje krawÄdĹş");
			for i of Graph loop
				Ada.Text_IO.Put(i.number'Img & " ---- [");
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

	type printerPointer is access Printer;
   	printerFunc: Printer;
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
   		
   		
   	procedure routingTable is
   	begin
   		for currentNode of Graph loop
   			for i in 0..n-1 loop
   				currentRouting:=new routing;
   				currentRouting.sender:=currentNode.number;
   				currentRouting.number:=i;
   				if (i=currentNode.number) then
   					currentRouting.changed:=true;
   				else
   					currentRouting.changed:=false;
   					if(currentNode.next.Contains(i)) then
   						
   						currentRouting.nextHop:=i;
   						currentRouting.cost:=200000;
   					else
   						if(currentNode.number<i) then
   							currentRouting.cost:=i-currentNode.number;
   							currentRouting.nextHop:=currentNode.number+1;
   						
   						else
   							currentRouting.cost:=currentNode.number-i;
   							currentRouting.nextHop:=currentNode.number-1;
   						
   						end if;
   					end if;
   				end if;
   				routingVectors.Append(currentNode.routing,currentRouting);
   			end loop;
   		end loop;
    end routingTable;
    procedure displayRouting is
    begin
    	for i of Graph loop
    		Ada.Text_IO.Put(i.number'Img & " ----- [");
    		for j of i.routing loop
    			Ada.Text_IO.Put(j.sender'Img);
    			Ada.Text_IO.Put(" ");
    			Ada.Text_IO.Put(j.number'Img);
    			Ada.Text_IO.Put(" ");
    			Ada.Text_IO.Put(j.nextHop'Img);
    			Ada.Text_IO.Put(" ");
    			Ada.Text_IO.Put(j.cost'Img);
    			Ada.Text_IO.Put(" ");
    			Ada.Text_IO.Put(j.changed'Img);
    			Ada.Text_IO.Put(" ");
    			Put_Line("");
    		end loop;
    		Put_Line("]");
    	end loop;
    end displayRouting;
    
   	task type Sender (node:vertexPointer) is
   		entry startRunning;
   	end Sender;
   	
   	task type Receiver (node:vertexPointer) is
   		entry startRunning;
   		entry receive(value: in routingVectors.Vector);
   	end Receiver;	
   	
   	type senderPointer is access Sender;
   	type receiverPointer is access receiver;
   	type senderArray is array (Integer range <>) of senderPointer;
   	type receiverArray is array(Integer range <>) of receiverPointer;
   	
   	senderArr:senderArray(0..n-1);
   	receiverArr:receiverArray(0..n-1);
   	
   	task body Sender is 
   		message: routingVectors.Vector;
   		zeroCounter:Integer:=0;
   		M : Mutex;
   	begin
   		loop
   			select
   				accept startRunning do
   					Put_Line("Sender wierzchoĹka " & node.number'Img & " rozpoczyna prace");
   				end startRunning;
   					loop
   						delay Duration(Float((Integer(random(gen)) mod 300)) / 100.0);
   						message.Clear;
   						M.Seize;
	   				    for j of node.routing loop
	   				    	if (j.changed=true) then
	   				    		routingVectors.Append(message,j);
	   				    		j.changed:=false;
	   				    	end if;
	   				    end loop;
	   				    M.Release;
	   				    if not message.Is_Empty then 
	   				    	M.Seize;
	   				    	zeroCounter:=0;
	   				    	printerFunc.print("Wierzcholek " & node.number'Img & " przygotowuje oferte");
	   				    	for j of message loop
	   				    		Ada.Text_IO.Put(j.sender'Img);
								Ada.Text_IO.Put(j.number'Img);
								Ada.Text_IO.Put(j.nextHop'Img);
								Ada.Text_IO.Put(j.cost'Img);
								Ada.Text_IO.Put(" ");
								Ada.Text_IO.Put(j.changed'Img);
								Put_Line("");
	   				    	end loop;
	   				    	M.Release;
	   				    	for j of node.next loop
	   				    		receiverArr(j).receive(message); 
	   				    	end loop;
	   				    else
	   				    	zeroCounter:=zeroCounter+1;
	   				    end if;
	   				    if zeroCounter=10 then
	   				    	M.Seize;
	   				    	reportCounter:=reportCounter+1;
	   				    	if reportCounter=n then
	   				    		displayRouting;
	   				    	end if;
	   				    	M.Release;
	   				    	exit;
	   				    end if;
   					end loop;
   					--<<Break_imitation_1>>
   				or
   					terminate;
   			end select;
   		end loop;
   	end Sender;
   	
	task body Receiver is
		--message: routingPointer;
		index:Integer;
		newCost:Integer;
		M : Mutex;
	begin
		loop
			select
				accept startRunning do
					null;
					Put_Line("Receiver wierzcholka " & node.number'Img & " rozpoczyna prace");
				end startRunning;
				or
				accept receive (value: in routingVectors.Vector) do
					Put_Line("Wierzcholek " & node.number'Img & " otrzymal paczke");
					M.Seize;
					for j of value loop
						index:=j.number;
						newCost:=j.cost+1;
						if(newCost<node.routing(index).cost) then
							node.routing(index).cost:=newCost;
							node.routing(index).nextHop:=j.sender;
							node.routing(index).changed:=true;
						end if;
					end loop;
					M.Release;
				end receive;
				M.Seize;
				for i of node.routing loop
					Ada.Text_IO.Put(i.sender'Img & " " & i.number'Img & " " & i.nextHop'Img & " " & i.cost'Img & " " & i.changed'Img );
    				Put_Line("");
    			end loop;
    			M.Release;
				or
					terminate;
			end select;
		end loop;
	end Receiver;
		
	begin
	if(d>((n-3)*n)/2) then
		Put_Line("Za duĹźo skrĂłtĂłw");
		return;
	end if;
	initNodes;
	shortcuts;
	displayGraph;
	routingTable;
	displayRouting;
	for i in 0..n-1 loop
		senderArr(i) := new Sender(node => Graph(i));
		receiverArr(i) := new Receiver(node => Graph(i));
	end loop;
	for i in 0..n-1 loop
		senderArr(i).startRunning;
	end loop;
	for i in 0..n-1 loop
		receiverArr(i).startRunning;
	end loop;
	end zad3;
