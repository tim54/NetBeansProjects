#include "Date.h"
#include <cstdlib>

using namespace std;

int bitSet(int num, int n){
    
    int mask = 1 << (n + 1);
    return num | mask;
}

/*
 * 
 */
int main(int argc, char** argv) {
    
    Date date = Date(21, Date::Month(06), 1985);
    // date.add_day(1);
    printf("Date is %s\n", date.string_rep().c_str());
    
    int num = 4;
    printf("Num is: %d\n", num);
    
    return 0;
}

