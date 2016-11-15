#include <cstdlib>
#include <iostream>
#include "LinkedList.h"
#include "Queue.h"

using namespace std;

int main(int argc, char** argv) {
    
    // =======================================================================
    // LinkedList test
    // =======================================================================
    LinkedList* list = new LinkedList();
    list->add(1);
    list->add(2);
    list->add(3);

    list->printList();
    
    // =======================================================================
    // Queue test
    // =======================================================================
    Queue<char> myQueue(14); // объект класса очередь
 
    myQueue.printQueue(); // вывод очереди
 
    int ct = 1;
    char ch;
 
    // добавление элементов в очередь
    while (ct++ < 14)
    {
        cin >> ch;
        myQueue.enqueue(ch);
    }
 
    myQueue.printQueue(); // вывод очереди
 
    // удаление элемента из очереди
    myQueue.dequeue();
    myQueue.dequeue();
    myQueue.dequeue();
 
    myQueue.printQueue(); // вывод очереди
 
    cout << "\n\nСработал конструктор копирования:\n";
    Queue<char> newQueue(myQueue);
 
    newQueue.printQueue(); // вывод очереди
    // =======================================================================
    // =======================================================================
    
    return 0;
}

