#ifndef LINKEDLIST_H
#define LINKEDLIST_H

class LinkedList {
public:

    struct Node {
    public:
        int item;
        Node* next;
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

