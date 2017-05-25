#include <iostream>

using namespace std;

int main() {
   
	for (int i{0}; i<8;i++){
	// 0 to 7C
	cout << "elsif co_value = x\"" << i << "0\" then\n"
		<< "--enable processor:" << i*4 + 0 << endl
        	<< "dp_i_enable("<< i*4+0 << ") <= \'1\';\n"
		<< "--disable processor:" << i*4 + 1 << endl
        	<< "dp_i_enable("<< i*4+1 << ") <= \'0\';\n";
	cout << "elsif co_value = x\"" << i << "4\" then\n"
		<< "--enable processor:" << i*4 +1 << endl
        	<< "dp_i_enable("<< i*4+1 << ") <= \'1\';\n"
		<< "--disable processor:" << i*4 + 2 << endl
        	<< "dp_i_enable("<< i*4+2 << ") <= \'0\';\n";
	cout << "elsif co_value = x\"" << i << "8\" then\n"
		<< "--enable processor:" << i*4 + 2 << endl
        	<< "dp_i_enable("<< i*4+2 << ") <= \'1\';\n"
		<< "--disable processor:" << i*4 + 3 << endl
        	<< "dp_i_enable("<< i*4+3 << ") <= \'0\';\n";
	cout << "elsif co_value = x\"" << i << "C\" then\n"
		<< "--enable processor:" << i*4 + 3 << endl
        	<< "dp_i_enable("<< i*4+3 << ") <= \'1\';\n"
		<< "--disable processor:" << i*4 + 4 << endl
        	<< "dp_i_enable("<< i*4+4 << ") <= \'0\';\n";
		
	}
	return 0;
}
