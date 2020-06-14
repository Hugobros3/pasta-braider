import std.random;

Mt19937 rng;

void seedRng() {
	rng.seed(unpredictableSeed);
}

@nogc float uniform_rng() {
	float val = (float(rng.front) * (1.0f / ((uint.max))));
	rng.popFront();
	return val;
}

@nogc int uniform_range(int lower, int upper) {
	int val = rng.front % (upper - lower); // bad ! modulo is slowz ...
	rng.popFront();
	return val + lower;
}