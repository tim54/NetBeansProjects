#include <exception>
#include <iostream>

#include "LinkedList.h"

using namespace std;

LinkedList::LinkedList() {
    first = nullptr;
    end = nullptr;
    n = 0;
}

LinkedList::LinkedList(const LinkedList& orig) {
}

LinkedList::~LinkedList() {
    if (first == nullptr)
        return;
    
    while (first->next != nullptr){

        Node* tmpNode = new Node();
        tmpNode = first;
        first = first->next;
        
        delete tmpNode;
        
    }
    end = nullptr;
    cout << "Linked list terminated";
}

bool LinkedList::isEmpty(int item) {
    return first == nullptr;
}

int LinkedList::size() {
    return n;
}

void LinkedList::add(int item) {
    Node* newNode = new Node();
    newNode->item = item;
    
    if (end != nullptr) {
        end->next = newNode;
        end = newNode;
    } else {
        first = end = newNode;
    }
}

void LinkedList::printList() {
    if (first == nullptr) {
        cout << "List: is empty" << endl;
        return;
    }
    
    Node* focusNode = first;
    
    cout <<  "List: " << endl;
    cout << "Node [" << focusNode->item << "]" << endl;
    
    while (focusNode->next != nullptr){
        focusNode = focusNode->next;
        cout << "Node [" << focusNode->item << "]" << endl;
    }
    cout << endl;
}

