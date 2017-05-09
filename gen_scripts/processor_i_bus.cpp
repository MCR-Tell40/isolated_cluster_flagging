// generate 4 datatrains of
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
  long int limit{1024}; // maximum value of column
  long int value;       // column address

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
  // commented out 09 may 17 by dónal murray
  // no longer use inflationary block as input
  // out << "0000" // 31-24
  //  << "0000";
  for (int i{0}; i < 10; i++) {
    mod = fmod(temp, 2);
    temp = floor(temp / 2);
    bin << mod;
  }
  // reverse the order
  binstr = bin.str();
  reverse(binstr.begin(), binstr.end());
  out << binstr;
  out << "00000000000011"; // 7-0
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

  // generate the rest
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

  // open output files
  ofstream unsorted("processor_unsorted.tcl");
  if (unsorted.fail()) {
    cerr << "Error: file failed to open.\n";
    return 1;
  }
  ofstream sorted("processor_sorted.dat");
  if (sorted.fail()) {
    cerr << "Error: file failed to open.\n";
    return 1;
  }

  // write out columns to files in tcl format
  unsorted << "force -freeze sim:/icf_processor/i_bus ";
  for (auto it = columns.begin(); it != columns.begin() + 15; it++) {
    unsorted << it->get_bin();
  }
  unsorted << " 6.25ns\n";

  unsorted << "force -freeze sim:/icf_processor/i_bus ";
  for (auto it = columns.begin() + 15; it != columns.begin() + 31; it++) {
    unsorted << it->get_bin();
  }
  unsorted << " 12.50ns\n";

  unsorted << "force -freeze sim:/icf_processor/i_bus ";
  for (auto it = columns.begin() + 31; it != columns.begin() + 47; it++) {
    unsorted << it->get_bin();
  }
  unsorted << " 18.75ns\n";

  unsorted << "force -freeze sim:/icf_processor/i_bus ";
  for (auto it = columns.begin() + 47; it != columns.begin() + 63; it++) {
    unsorted << it->get_bin();
  }
  unsorted << " 25.00ns\n";

  // close file
  unsorted.close();
  if (unsorted.fail()) {
    cerr << "Error: could not save unsorted columns to file.\n";
    return 1;
  }

  sort(columns.begin(), columns.end(),
       [](const column &lhs, const column &rhs) {
         return lhs.get_value() < rhs.get_value();
       });

  // write out sorted columns to file
  for (auto it = columns.begin(); it != columns.end(); it++) {
    sorted << it->get_bin() << endl;
  }

  // close file
  sorted.close();
  if (sorted.fail()) {
    cerr << "Error: could not save sorted columns to file.\n";
    return 1;
  }

  // exit
  cout << "Success.\n";
  return 0;
}
