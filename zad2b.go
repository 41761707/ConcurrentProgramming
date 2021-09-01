package main

import (
	"fmt"
	"os"
	"math/rand"
	"sync"
    "time"
	"strconv"
)
var mutex = &sync.Mutex{}
var packetCounter int
var pf []point
type node struct{
	number int
	in chan point
	out []*chan point
	numbers []int
	next []int
	printer *chan string
	trap chan bool
}
type point struct{
	value int
	visitedNodes []int
	ttl int
}
func initNodes(nodes []node, n int){
	printer := make(chan string)
	for i:=0;i<n-1;i++{
		nodes[i]=node{number:i,in:make(chan point),printer:&printer,trap:make(chan bool)}
	} 
	nodes[n-1]=node{number:n-1,in:make(chan point),printer:&printer,trap:make(chan bool)}
}
func myPrinter(printer <-chan string){
	for{
		message:=<-printer
		fmt.Println(message)
	}
}
//TO-DO: more efficient way of finding shortcuts
func initEdges(nodes []node, d int,b int,n int){
	for i:=0;i<n-1;i++{
		nodes[i].out=append(nodes[i].out,&nodes[i+1].in)
		nodes[i].next=append(nodes[i].next,i+1)
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
    	for j:=range nodes[first].next{
    		if(nodes[first].next[j]==second){
    			flag=true
    			break
    		}
    	}
    	if(flag){
    		flag=false
    		continue
    	}else{
    		nodes[first].out=append(nodes[first].out,&nodes[second].in)
    		nodes[first].next=append(nodes[first].next,second)
    		i=i+1
    	}
	}
	i=0
	flag=false
	for i<b{
		second=ra.Intn(n-2)
		first=ra.Intn((n-1)-(second+1))+(second+1)
		for j:=range nodes[first].next{
    		if(nodes[first].next[j]==second){
    			flag=true
    			break
    		}
    	}
    	if(flag){
    		flag=false
    		continue
    	}else{
    		nodes[first].out=append(nodes[first].out,&nodes[second].in)
    		nodes[first].next=append(nodes[first].next,second)
    		i=i+1
    	}
	}
}
func initPoints(points []point, k int,h int){
	for i:=0;i<k;i++{
		points[i]=point{value:i,ttl:h}
	}
}

func disturb(nodes []node,printer *chan string){
	s1 := rand.NewSource(time.Now().UnixNano())
	r1:= rand.New(s1)
	for{
		delay:=r1.Intn(8)
		next := rand.Intn(len((nodes)))
		message:="PuĹapka zostaĹa umieszczona w wierzchoĹku "+strconv.Itoa(nodes[next].number)
		*printer <-message
		nodes[next].trap <- true
		time.Sleep(time.Duration(delay))
	}
}
/*func sender(nodes []node, points []point,i int,k int,nf []node){
		s1 := rand.NewSource(time.Now().UnixNano())
		r1:= rand.New(s1)	
		node:=nodes[i]
		for j:=0;j<k;j++{
			point:=points[j]
			point.visitedNodes=append(point.visitedNodes,i)
			node.numbers=append(node.numbers,point.value)
			delay:=r1.Intn(8)
			nf[node.number]=node
			message:="Sender wysyla pakiet: "+strconv.Itoa(j)
			*node.printer <- message
			temp := rand.Intn(len(node.next))
			*node.out[temp] <- point
			time.Sleep(time.Duration(delay))
		}
		fmt.Println("Sender koĹczy dziaĹanie")
		return
}*/
func sender(send *chan point,points []point,k int, printer *chan string){
	s1 := rand.NewSource(time.Now().UnixNano())
	r1:= rand.New(s1)
	for j:=0;j<k;j++{
		point:=points[j]
		delay:=r1.Intn(8)
		message:="Sender wysyla pakiet: " +strconv.Itoa(j)
		*printer<-message
		*send<-point
		time.Sleep(time.Duration(delay))
	}
}
/*func receiver(nodes []node,points []point,i int, k int,nf []node,pf []point,wait chan<- bool){
	s1 := rand.NewSource(time.Now().UnixNano())
	r1:= rand.New(s1)
	node:=nodes[i]
	packetCounter:=0
	for{
		delay:=r1.Intn(8)
		point := <-node.in
		packetCounter=packetCounter+1
		point.visitedNodes=append(point.visitedNodes,i)
		node.numbers=append(node.numbers,point.value)
		nf[node.number]=node
		pf[point.value]=point
		message:="Pakiet "+strconv.Itoa(point.value)+" zostal odebrany"
		*node.printer <-message
		if(packetCounter==k){
			wait <- true
			return
		}
		time.Sleep(time.Duration(delay))
	}
}*/
func receiver(receive *chan point, k int,n int, wait chan<- bool, printer *chan string){
	s1 := rand.NewSource(time.Now().UnixNano())
	r1:= rand.New(s1)
	for{
		delay:=r1.Intn(8)
		point := <-*receive
		message:="Pakiet "+strconv.Itoa(point.value)+" zostal odebrany"
		*printer <-message
		mutex.Lock()
		pf=append(pf,point)
		packetCounter=packetCounter+1
		if(packetCounter==k){
			mutex.Unlock()
			wait <- true
			return
		}
		mutex.Unlock()
		time.Sleep(time.Duration(delay))
	}
}
func forward(out []*chan point, point point){
	next := rand.Intn(len((out)))
	select {
	case *out[next] <- point:

	default:
		forward(out,point)
	}
}
func listener(node *node,i int,k int,n int,wait chan bool){
	s1 := rand.NewSource(time.Now().UnixNano())
	r1:= rand.New(s1)
	trap:=false
	for{
		select{
			default:
				point:= <-node.in
				alreadyExists:=false
				if(trap){
					message:="Pakiet "+strconv.Itoa(point.value)+" zostal uszkodony w wierzcholku "+strconv.Itoa(node.number)
					*node.printer<-message
					point.visitedNodes=append(point.visitedNodes,i)
					for _,i :=range (*node).numbers{
							if i==point.value{
								alreadyExists=true
								break
							}
						}
					if(!alreadyExists){
						(*node).numbers=append((*node).numbers,point.value)
					}
					point.ttl=-1
					trap=false
					mutex.Lock()
					pf=append(pf,point)
					packetCounter=packetCounter+1
					if(packetCounter==k){
						mutex.Unlock()
						wait <-true
						return
					}
					mutex.Unlock()
				}else{
					if(point.ttl==0){
						
						message:="Pakiet "+strconv.Itoa(point.value)+" zmarl w wierzcholku "+strconv.Itoa(node.number)
						*node.printer<-message
						point.visitedNodes=append(point.visitedNodes,i)
						for _,i :=range (*node).numbers{
							if i==point.value{
								alreadyExists=true
								break
							}
						}
						if(!alreadyExists){
							(*node).numbers=append((*node).numbers,point.value)
						}
						mutex.Lock()
						pf=append(pf,point)
						packetCounter=packetCounter+1
						if(packetCounter==k){
							mutex.Unlock()
							wait <-true
							return
						}
						mutex.Unlock()
					}else{
						point.ttl=point.ttl-1
						message:="Pakiet "+strconv.Itoa(point.value)+" jest w wierzcholku "+strconv.Itoa(node.number)
						*node.printer<-message
						point.visitedNodes=append(point.visitedNodes,i)
						for _,i :=range (*node).numbers{
							if i==point.value{
								alreadyExists=true
								break
							}
						}
						if(!alreadyExists){
							(*node).numbers=append((*node).numbers,point.value)
						}
						forward(node.out,point)
						//temp := rand.Intn(len(node.next))
						//*node.out[temp] <- point
					}
				}
				delay:=r1.Intn(8)
				time.Sleep(time.Duration(delay))
			case <-node.trap:
				trap=true
			case <-wait:
				return
		}
	}
}

func main(){
	packetCounter=0
	n,_:=strconv.Atoi(os.Args[1])
	d,_:=strconv.Atoi(os.Args[2])
	b,_:=strconv.Atoi(os.Args[3])
	k,_:=strconv.Atoi(os.Args[4])
	h,_:=strconv.Atoi(os.Args[5])
	if(d>((n-3)*n)/2 || b>((n-3)*n)/2){
		fmt.Println("Nie mozna utworzyc tylu skrotow")
		return
	}
	nodes:=make([]node,n)
	initNodes(nodes,n)
	initEdges(nodes,d,b,n)
	points:=make([]point,k)
	initPoints(points,k,h)
	receive:=make(chan point)
	nodes[n-1].out=append(nodes[n-1].out,&receive)
    //nodes[n-1].next=append(nodes[n-1].next,n)
	printer:=make(chan string)
	fmt.Println("WierzchoĹek ----> WierzchoĹek")
	fmt.Println("StrzaĹka symobilizuje krawÄdĹş skierowanÄ")
	for i:=0;i<n;i++{
		nodes[i].printer=&printer
		fmt.Println(nodes[i].number, " ----> ",nodes[i].next)
	}
	go myPrinter(printer)
	wait:=make(chan bool)
	go sender(&nodes[0].in,points,k,&printer)
	go receiver(nodes[n-1].out[0],k,n,wait,&printer)
	for i:=0;i<n;i++{
			go listener(&nodes[i],i,k,n,wait)
	}
	go disturb(nodes,&printer)
	<-wait
	time.Sleep(1)
	fmt.Println("PodrĂłz punktĂłw: ")
	fmt.Println("Punkt ------> WierzchoĹki, ktĂłre odwiedziĹ")
	for i:=0;i<k;i++{
		fmt.Println(pf[i].value, " -------> ",pf[i].visitedNodes)
	}
	fmt.Println("WierzchoĹki: ")
	fmt.Println("WierzchoĹek -----> Punkty, ktĂłre go odwiedziĹy")
	for i:=0;i<n;i++{
		fmt.Println(nodes[i].number, " -----> ",nodes[i].numbers)
	}
}