// generate 512 unique, unordered bcids
// Author: Dónal Murray <donal.murray@cern.ch>

#include <cmath>    // fmod
#include <fstream>  // file io
#include <iostream> // std io
#include <sstream>  // stringstream
#include <string>   // string
#include <vector>   // vector

using namespace std;

class bcid // class for the 32 bit bcid
{
private:
  long int limit{4294967296}; // maximum value of bcid
  long int value;             // bcid

public:
  // constructor
  bcid(const long int raw) : value{(long int)(fmod(raw, limit))} {}
  // destructor
  ~bcid() {}

  // member functions
  long int get_value() const { return value; } // return decimal
  string get_bin() const;                      // return binary
};

// convert the value (<512) to a 9 bit binary number
string bcid::get_bin() const {
  stringstream bin;
  long int temp{value};
  long int mod;
  for (int i{0}; i < 32; i++) {
    mod = fmod(temp, 2);
    temp = floor(temp / 2);
    bin << mod;
    // doesn't matter that it is backwards, will still be unique and <512
  }
  return bin.str();
}

int main() {
  vector<bcid> bcids;
  bool flag; // avoid duplicates
  int nr{0}; // keep track of number

  // generate first bcid and push onto vector
  bcid bcid_temp(rand());
  bcids.push_back(bcid_temp);

  // generate the rest and make sure there are no duplicates
  while (bcids.size() != 100000) {
    flag = false;
    bcid bcid_temp(rand());
    for (auto it = bcids.begin(); it != bcids.end(); it++) {
      // iterate through bcids
      if (bcid_temp.get_value() == it->get_value()) {
        // this bcid already exists, flag for bypass
        flag = true;
      }
    }
    if (!flag) {
      // bcid is unique, add to vector
      bcids.push_back(bcid_temp);
      nr++;
      if (fmod(nr, 1000) == 0) {
        cout << nr << " words produced\n";
      }
    }
  }

  // open output file
  ofstream data_in("data_in.dat");
  if (data_in.fail()) {
    cerr << "Error: file failed to open.\n";
    return 1;
  }

  // write out bcids to file
  for (auto it = bcids.begin(); it != bcids.end(); it++) {
    data_in << it->get_bin() << endl;
  }

  // close file
  data_in.close();
  if (data_in.fail()) {
    cerr << "Error: could not save bcids to file.\n";
    return 1;
  }

  // exit
  cout << "Success.\n";
  return 0;
}
