#ifndef DATE_H
#define DATE_H

#include <string>
using std::string;

class Date {
public:
    enum Month { jan = 1, feb, mar, apr, may, jun ,jul, aug, sep, oct, nov, dec };

    Date(int dd = 0, Month mm = Month(0), int yy = 0);
    Date(const Date& orig);
    virtual ~Date();
    
    int day() const;
    Month month() const;
    int year() const;
    string string_rep() const;
    void char_rep(char s[]) const;
    static void set_default(int yy, Month mm, int dd){
        default_date = Date(yy, mm, dd);
    }
    
    Date& add_year(int n);
    Date& add_month(int n);
    Date& add_day(int n);
private:
    int d, m, y;
    static Date default_date;
};

#endif /* DATE_H */

