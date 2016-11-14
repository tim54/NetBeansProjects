/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/* 
 * File:   LinkedList.h
 * Author: artemkovalevsky
 *
 * Created on November 14, 2016, 12:15 PM
 */

#ifndef LINKEDLIST_H
#define LINKEDLIST_H

class LinkedList {
public:

    struct Node {
    public:
        int item;
        Node* next;

//        Node();
//        // Node(int item) { this->item = item; next = nullptr; }
//        virtual ~Node();
    };

    LinkedList();
    LinkedList(const LinkedList& orig);
    virtual ~LinkedList();
    bool isEmpty(int item);
    int size();
    void add(int item);
    void printList();
private:
    Node* first;
    Node* end;
    int n;

};

#endif /* LINKEDLIST_H */

