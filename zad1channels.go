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
type node struct{
	number int
	in chan point
	out []*chan point
	numbers []int
	next []int
	printer *chan string
}
type point struct{
	value int
	visitedNodes []int
}
func initNodes(nodes []node, n int){
	printer := make(chan string)
	for i:=0;i<n-1;i++{
		nodes[i]=node{number:i,in:make(chan point),printer:&printer}
	} 
	nodes[n-1]=node{number:n-1,in:make(chan point),printer:&printer}
}
func myPrinter(printer <-chan string){
	for{
		message:=<-printer
		fmt.Println(message)
	}
}
//TO-DO: more efficient way of finding shortcuts
func initEdges(nodes []node, d int,n int){
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
}
func initPoints(points []point, k int){
	for i:=0;i<k;i++{
		points[i]=point{value:i}
	}
}
func sender(nodes []node, points []point,i int,k int,nf []node){
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
}
func receiver(nodes []node,points []point,i int, k int,nf []node,pf []point,wait chan<- bool){
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
		//message:="Pakiet "+strconv.Itoa(point.value)+" jest w wierzchoĹku "+strconv.Itoa(node.number)
		//*node.printer <- message
		//fmt.Println("Pakiet ", point.value, " zostal odebrany")
		message:="Pakiet "+strconv.Itoa(point.value)+" zostal odebrany"
		*node.printer <-message
		if(packetCounter==k){
			wait <- true
			return
		}
		time.Sleep(time.Duration(delay))
	}
	
	
}
func listener(nodes []node, points []point,i int,k int,nf []node,wait chan bool){
	s1 := rand.NewSource(time.Now().UnixNano())
	r1:= rand.New(s1)
	node:=nodes[i]
	mutex.Lock()
	nf[node.number]=node
	mutex.Unlock()
	for{
		select{
			default:
				point:= <-node.in
				//fmt.Println("Pakiet ", point.value, " jest w wierzchoĹku ",node.number)
				message:="Pakiet "+strconv.Itoa(point.value)+" jest w wierzcholku "+strconv.Itoa(node.number)
				*node.printer<-message
				delay:=r1.Intn(8)
				point.visitedNodes=append(point.visitedNodes,i)
				node.numbers=append(node.numbers,point.value)
				nf[node.number]=node
				temp := rand.Intn(len(node.next))
				*node.out[temp] <- point
				time.Sleep(time.Duration(delay))
			case <-wait:
				return
		}
	}
}
func main(){
	n,_:=strconv.Atoi(os.Args[1])
	d,_:=strconv.Atoi(os.Args[2])
	k,_:=strconv.Atoi(os.Args[3])
	nodes:=make([]node,n)
	initNodes(nodes,n)
	initEdges(nodes,d,n)
	points:=make([]point,k)
	initPoints(points,k)
	nodesFinal:=make([]node,n)
	pointsFinal:=make([]point,k)
	printer:=make(chan string)
	fmt.Println("WierzchoĹek ----> WierzchoĹek")
	fmt.Println("StrzaĹka symobilizuje krawÄdĹş skierowanÄ")
	for i:=0;i<n;i++{
		nodes[i].printer=&printer
		fmt.Println(nodes[i].number, " ----> ",nodes[i].next)
	}
	go myPrinter(printer)
	wait:=make(chan bool)
	for i:=0;i<n;i++{
		if(i==0){
			go sender(nodes,points,i,k,nodesFinal)
		}else if(i==n-1){
			go receiver(nodes,points,i,k,nodesFinal,pointsFinal,wait)
		}else{
			go listener(nodes,points,i,k,nodesFinal,wait)
		}
	}
	<-wait
	fmt.Println("PodrĂłz punktĂłw: ")
	fmt.Println("Punkt ------> WierzchoĹki, ktĂłre odwiedziĹ")
	for i:=0;i<k;i++{
		fmt.Println(pointsFinal[i].value, " -------> ",pointsFinal[i].visitedNodes)
	}
	fmt.Println("WierzchoĹki: ")
	fmt.Println("WierzchoĹek -----> Punkty, ktĂłre go odwiedziĹy")
	for i:=0;i<n;i++{
		fmt.Println(nodesFinal[i].number, " -----> ",nodesFinal[i].numbers)
	}
}