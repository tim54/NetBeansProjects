#include "Date.h"
#include <iostream>
#include <cstdlib>
#include <bitset>

using namespace std;

int bitsCount(int num){
    int size = sizeof(int);
    
}

int bitSet(int num, int n){
    
    int mask = 1 << (n - 1);
    return num | mask;
}

/*
 * 
 */
int main(int argc, char** argv) {
    
    Date date = Date(21, Date::Month(06), 1985);

    printf("Date is %s\n", date.string_rep().c_str());
    // =======================================================================
    // Binary operations test
    // =======================================================================
    int num = 4;
    cout << bitset<8>(num) << endl;
    
    int modifNum = bitSet(num, 5);
    cout << bitset<8>(modifNum) << endl;
    
    
    return 0;
}

