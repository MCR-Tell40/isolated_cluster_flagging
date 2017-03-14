// generate a 512 bit array in tcl format to be loaded directly into modelsim
// Author: Dónal Murray <donal.murray@cern.ch>
// adapted (lazily) from bcid generator

#include <cmath>    // fmod
#include <fstream>  // file io
#include <iostream> // std io
#include <sstream>  // stringstream
#include <string>   // string
#include <vector>   // vector

using namespace std;

class bit // class for the bit
{
private:
  long int value; // 1 or 0

public:
  // constructor
  bit(const long int raw) : value{(long int)(fmod(raw, 2))} {}
  // destructor
  ~bit() {}

  // member functions
  long int get_value() const { return value; } // return decimal
};

int main() {
  vector<bit> bits;

  // generate first bit and push onto vector
  bit bit_temp(rand());
  bits.push_back(bit_temp);
  int nr{1}; // keep track of number of bits

  // generate the rest and make sure there are no duplicates
  while (bits.size() != 512) {
    bit bit_temp(rand());
    bits.push_back(bit_temp);
    cout << ++nr << " bits produced\n";
  }

  // open output file
  ofstream data_in("rd_data_gen.tcl");
  if (data_in.fail()) {
    cerr << "Error: file failed to open.\n";
    return 1;
  }

  // write out to file
  int j{0};
  for (auto it = bits.begin(); it != bits.end(); it++) {
    data_in << "force -freeze sim:/sppif_top/rd_data(" << j++ << ") "
            << it->get_value() << " 0\n";
  }

  // close file
  data_in.close();
  if (data_in.fail()) {
    cerr << "Error: could not save bits to file.\n";
    return 1;
  }

  // exit
  cout << "Success.\n";
  return 0;
}
