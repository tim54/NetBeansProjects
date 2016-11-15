#ifndef STRING_SPRINTF_H
#define STRING_SPRINTF_H

#include <cstdio>
#include <string>
#include <cassert>

using namespace std;

template< typename... Args >
std::string string_sprintf( const char* format, Args... args ) {
  int length = std::snprintf( nullptr, 0, format, args... );
  assert( length >= 0 );

  char* buf = new char[length + 1];
  std::snprintf( buf, length + 1, format, args... );

  std::string str( buf );
  delete[] buf;
  return std::move(str);
}

#endif /* STRING_SPRINTF_H */

