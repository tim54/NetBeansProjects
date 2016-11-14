/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/* 
 * File:   datatypestest.cpp
 * Author: artemkovalevsky
 *
 * Created on November 14, 2016, 12:21 PM
 */

#include <cstdlib>
#include "LinkedList.h"

using namespace std;

/*
 * 
 */
int main(int argc, char** argv) {
    
    LinkedList* list = new LinkedList();
    list->add(1);
    list->add(2);
    list->add(3);

    list->printList();
    
    return 0;
}

