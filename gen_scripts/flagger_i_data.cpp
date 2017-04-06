// generate 512 unique, unordered columns
// Author: Dónal Murray <donal.murray@cern.ch>

#include <algorithm>
#include <cmath>    // fmod
#include <fstream>  // file io
#include <iostream> // std io
#include <iterator>
#include <sstream> // stringstream
#include <string>  // string
#include <vector>  // vector

using namespace std;

class column // class for bit 8 to bit 13
{
private:
  long int limit{64}; // maximum value of column
  long int value;     // column address

public:
  // constructor
  column(const long int raw) : value{(long int)(fmod(raw, limit))} {}
  // destructor
  ~column() {}

  // member functions
  long int get_value() const { return value; } // return decimal
  string get_bin() const;                      // return binary
};

// convert the value (<512) to a 9 bit binary number
string column::get_bin() const {
  stringstream bin;
  stringstream out;
  string binstr;
  long int temp{value};
  long int mod;
  out << "0000" // 31-14
      << "0000" //
      << "0000" //
      << "0000" //
      << "00";  //
  for (int i{0}; i < 6; i++) {
    mod = fmod(temp, 2);
    temp = floor(temp / 2);
    bin << mod;
  }
  // reverse the order
  binstr = bin.str();
  reverse(binstr.begin(), binstr.end());
  out << binstr;
  out << "00000011"; // 7-0
  // 1s to avoid being flagged as edge cases, even when addr is 000000
  return out.str();
}

int main() {
  vector<column> columns;
  bool flag; // avoid duplicates
  int nr{0}; // keep track of number

  // generate first column and push onto vector
  srand(time(NULL));
  column column_temp(rand());
  columns.push_back(column_temp);

  // generate the rest and make sure there are no duplicates
  while (columns.size() != 64) {
    flag = false;
    column column_temp(rand());
    // for (auto it = columns.begin(); it != columns.end(); it++) {
    // iterate through columns
    // if (column_temp.get_value() == it->get_value()) {
    // this column already exists, flag for bypass
    // flag = true;
    // }
    //}
    if (!flag) {
      // column is unique, add to vector
      columns.push_back(column_temp);
      nr++;
      cout << nr << " words produced\n";
    }
  }

  // open output file
  ofstream data_in("flagger_i_data.tcl");
  if (data_in.fail()) {
    cerr << "Error: file failed to open.\n";
    return 1;
  }

  sort(columns.begin(), columns.end(),
       [](const column &lhs, const column &rhs) {
         return lhs.get_value() < rhs.get_value();
       });

  // write out columns to file in tcl format
  int i = 0;
  for (auto it = columns.begin(); it != columns.end(); it++) {
    data_in << "mem load -filltype value -filldata " << it->get_bin()
            << " -fillradix binary sim:/flagger/i_data(" << i++ << ")\n";
  }

  // close file
  data_in.close();
  if (data_in.fail()) {
    cerr << "Error: could not save columns to file.\n";
    return 1;
  }

  // exit
  cout << "Success.\n";
  return 0;
}
