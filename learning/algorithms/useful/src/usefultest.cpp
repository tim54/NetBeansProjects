#include "Date.h"
#include <iostream>
#include <cstdlib>
#include <bitset>

using namespace std;

int bitsCount(int num){
    int counter = 0;
    while (num != 0){
        if ((num & 1) != 0)
            counter++;
        num >>= 1;
    }
    return counter;
}

int fourBitsReverse(char num){
    // cout << "Sizeof char: " << sizeof(char) << endl;
    int counter = 0;
    bool buf[8];
    for (int i = 0; i < 8; i++){
        buf[7 - i] = num & 1;
        num >>= 1;
        cout << "Buf 1: i: " << i << ", val: " << buf[7 - i] << endl;
    }
    
    bool tmp;
    for (int i = 0; i < 4; i++){
        tmp = buf[i];
        buf[i] = buf[7 - i];
        buf[7 - i] = tmp;
        cout << "Buf 2: " << buf[7 - i] << endl;
    }
    
    return 0;
}

int bitSet(int num, int n) {
    
    int mask = 1 << (n - 1);
    return num | mask;
}

bool bitGet(int num, int n) {
    int mask = 1 << (n - 1);
    return num & mask;
}

int clearBit(int num, int n){
    int mask = ~(1 << (n - 1));
    return num & mask;
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
    int num = 255;
    cout << bitset<8>(num) << endl;
    
    int modifNum = bitSet(num, 5);
    cout << bitset<8>(modifNum) << endl;
    
    int res = bitsCount(num);
    cout << "Res: " << res << endl;
    
    cout << "A: " << bitset<8>('A') << endl;
    res = fourBitsReverse('A');
    cout << "res: " << bitset<32>(res) << endl;
    return 0;
}

