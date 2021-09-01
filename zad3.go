package main

import(
	"fmt"
	"strconv"
	"sync"
	"math/rand"
	"time"
	"os"
)
type routingTable struct{
	sender int
	number int
	nextHop int
	cost int
	changed bool
}
type node struct{
	number int
	in chan []routingTable
	out []*chan []routingTable
	neighbour []int
	routing []routingTable
	m sync.Mutex
}
func intInSlice(a int, list []int) bool {
    for _, b := range list {
        if b == a {
            return true
        }
    }
    return false
}



func initNodes(nodes []node, n int){
	for i:=0;i<n;i++{
		nodes[i]=node{number:i,in:make(chan []routingTable)}
	}
}

func initEdges(nodes []node, n int, d int){
	for i:=0;i<n-1;i++{
		nodes[i].out=append(nodes[i].out,&nodes[i+1].in)
		nodes[i].neighbour=append(nodes[i].neighbour,i+1)
		nodes[i+1].out=append(nodes[i+1].out,&nodes[i].in)
		nodes[i+1].neighbour=append(nodes[i+1].neighbour,i)
	}
	s1 := rand.NewSource(time.Now().UnixNano())
    ra:= rand.New(s1)
    first:=0
    second:=0
    flag:=false
    i:=0
	for i<d{
		first=ra.Intn(n-2)
    	second=ra.Intn((n-1)-(first+1))+(first+1)
    	for j:=range nodes[first].neighbour{
    		if(nodes[first].neighbour[j]==second){
    			flag=true
    			break
    		}
    	}
    	if(flag){
    		flag=false
    		continue
    	}else{
    		nodes[first].out=append(nodes[first].out,&nodes[second].in)
    		nodes[first].neighbour=append(nodes[first].neighbour,second)
    		nodes[second].out=append(nodes[second].out,&nodes[first].in)
    		nodes[second].neighbour=append(nodes[second].neighbour,first)
    		i=i+1
    	}
	}

}

//TO-DO: make appropriate packet
func initRoutingTable(currentNode *node, n int){
	currentNode.routing=make([]routingTable,n)
	for i:=0;i<n;i++{
		currentNode.routing[i].sender=currentNode.number
		currentNode.routing[i].number=i
		if(i==currentNode.number){
			currentNode.routing[i].changed=true
			continue
		}else{
			currentNode.routing[i].changed=false
			if(intInSlice(i,currentNode.neighbour)){
				currentNode.routing[i].nextHop=i
				currentNode.routing[i].cost=200000
			}else{
				if(currentNode.number<i){
					currentNode.routing[i].cost=i-currentNode.number
					currentNode.routing[i].nextHop=currentNode.number+1
				}else{
					currentNode.routing[i].cost=currentNode.number-i
					currentNode.routing[i].nextHop=currentNode.number-1
				}
			}
		}
	}
}

func sender(currentNode *node,wait chan bool){
	zeroCounter:=0
	for{
		select{
			default:
				time.Sleep(time.Millisecond*500)
				message:=make([]routingTable,0)
				currentNode.m.Lock()
				for i,r:=range currentNode.routing{
					if r.changed==true{
						message=append(message,r)
						currentNode.routing[i].changed=false
					}
				}
				currentNode.m.Unlock()
				
				if len(message)>0{
					fmt.Println("Wierzcholek", currentNode.number,"przygotowuje oferte",message)
					zeroCounter=0
					for _,out :=range currentNode.out{
						*out <- message
					}
				}else{
					zeroCounter=zeroCounter+1
				}
				if(zeroCounter==15){
					wait <- true
					return
				}
		}
	}
} 
func receiver(currentNode *node){
	for{
		select{
			case message:=<-currentNode.in:
				currentNode.m.Lock()
				fmt.Println("Wierzcholek",currentNode.number,"otrzymal oferte",message)
				for _,r :=range message{
					index:=r.number
					newCost:=r.cost+1
					if newCost<currentNode.routing[index].cost{
						currentNode.routing[index].cost=newCost
						currentNode.routing[index].nextHop=r.sender
						currentNode.routing[index].changed=true
					}
				}
				currentNode.m.Unlock()
				fmt.Println("Wierzcholek", currentNode.number, "stan: ", currentNode.routing)
				case <-time.After(3 * time.Second):
					return
				
		}
	}
}
func main(){
	n,_:=strconv.Atoi(os.Args[1])
	d,_:=strconv.Atoi(os.Args[2])
	if(d>((n-3)*n)/2){
		fmt.Println("Nie mozna utworzyc tylu skrotow")
		return
	}
	nodes:=make([]node,n)
	initNodes(nodes,n)
	initEdges(nodes,n,d)
	fmt.Println("WierzchoĹek <----> WierzchoĹek")
	for i:=0;i<n;i++{
		fmt.Println(nodes[i].number, " <----> ",nodes[i].neighbour)
	}
	for i:=0;i<n;i++{
		initRoutingTable(&nodes[i],n)
	}
	wait:=make(chan bool)
	for i:=0;i<n;i++{
		go sender(&nodes[i],wait)
		go receiver(&nodes[i])
	}
	<-wait
	fmt.Println("Ostateczny stan routing table dla kaĹźdego wierzchoĹka")
	fmt.Println("--------------------");
	for i:=0;i<n;i++{
		fmt.Println(nodes[i].number,nodes[i].routing)
	}
	
}