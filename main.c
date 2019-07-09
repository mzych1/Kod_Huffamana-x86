// =====================================================================
 // ARKO - projekt 2

 // Autor: Magdalena Zych
 // Data:  2019-05-16
 // Opis:  Kodowanie/dekodowanie Huffmana

// =====================================================================
#include <stdio.h>
#ifdef __cplusplus
extern "C" {
#endif
	struct element
	{
		int number;
		short int sign;
		short int flag;
		int left;
		int right;
	} tree[511];
	int elementsNumber = 0;
	int numberBits = 0;
	int statistics[256]; //licznosci poszczegolntch znakow
	void doStatistics(int *st, char *inputFileName);
	void huffmanTree(int *st, struct element *tree, int *elementsNumber);
	void createCodes(struct element *tree, int elementsNumber);
	void printCodes(struct element *tree, int elementsNumber);
	void countBits(int *st, struct element *tree, int *numberBits, int elementsNumber);
	void codeFile(int *st, char *inputFileName, char *outputFileName, int *numberBits, int elementsNumber, struct element *tree);
	void readHeader(int *st, char *inputFileName, int *numberBits);
	void decodeFile(struct element *tree, char *outputFileName, int numberBits, int elementsNumber);
	void printStatAndCodes(int *st, struct element *tree);
#ifdef __cplusplus
}
#endif

void printStatisticsAndCodes();

int main(int argc, char** argv)
{
	if(argc != 4)
	{
		printf("Niepoprawna ilosc argumentow. Wymagane argumenty: wybor dzialania [k-kodowanie, d-dekodowanie], nazwa pliku wejsciowego, nazwa pliku wyjsciowego\n");
		return 1;
	}
	if(!strcmp(argv[1], "k"))
	{
		doStatistics(statistics, argv[2]); //zapisywanie licznosci znakow z pliku wejsciowego do tablicy statistics
		huffmanTree(statistics, tree, &elementsNumber); //dodawanie elementow poczatkowych, tworzenie drzewa, resetowanie flagi
		createCodes(tree, elementsNumber);
		printStatAndCodes(statistics, tree);
		countBits(statistics, tree, &numberBits, elementsNumber);
		codeFile(statistics, argv[2], argv[3], &numberBits, elementsNumber, tree);
	}
	else if(!strcmp(argv[1], "d"))
	{
		readHeader(statistics, argv[2], &numberBits); //uzupelnia tablice statistics oraz odczytuje zmienna numberBits
		huffmanTree(statistics, tree, &elementsNumber); //dodawanie elementow poczatkowych, tworzenie drzewa, resetowanie flagi
		createCodes(tree, elementsNumber);
		printStatAndCodes(statistics, tree);
		decodeFile(tree, argv[3], numberBits, elementsNumber);
	}
	else
		printf("Niepoprawny argument.  Wymagane argumenty: wybor dzialania [k-kodowanie, d-dekodowanie], nazwa pliku wejsciowego, nazwa pliku wyjsciowego\n");
	
	return 0;
}