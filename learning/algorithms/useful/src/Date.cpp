#include "Date.h"
#include "string_sprintf.h"

using namespace std;

Date::Date(int yy, Month mm, int dd){
    d = dd;
    m = mm;
    y = yy;
}

Date::Date(const Date& orig) {
}

Date::~Date() {
}

int Date::day() const {
    return d;
}

Date::Month Date::month() const {
    return static_cast<Month>(m);
}

int Date::year() const{
    return y;
}

string Date::string_rep() const{
    return string_sprintf("Date: %d-%d-%d", y, m, d);
}


