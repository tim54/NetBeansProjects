#include <cstdlib>
#include <iostream>
#include "LinkedList.h"
#include "Queue.h"
#include "Stack.h"

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
    // Stack test
    // =======================================================================
     Stack<char> stackSymbol(5);
    ct = 0;

    while (ct++ < 5)
    {
        cin >> ch;
        stackSymbol.push(ch); // помещаем элементы в стек
    }
 
    cout << endl;
 
    stackSymbol.printStack(); // печать стека
 
    cout << "\n\nУдалим элемент из стека\n";
    stackSymbol.pop();
 
    stackSymbol.printStack(); // печать стека
 
    Stack<char> newStack(stackSymbol);
 
    cout << "\n\nСработал конструктор копирования!\n";
    newStack.printStack();
 
    cout << "Второй в очереди элемент: "<< newStack.Peek(2) << endl;
    // =======================================================================
    // =======================================================================
    
    return 0;
}

