#include "Date.h"
#include <cstdlib>

using namespace std;

/*
 * 
 */
int main(int argc, char** argv) {
    
    Date date = Date(21, Date::Month(06), 1985);
    // date.add_day(1);
    printf("Date is %s", date.string_rep().c_str());

    return 0;
}

