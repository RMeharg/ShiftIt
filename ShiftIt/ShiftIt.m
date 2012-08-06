BOOL AreClose(float a, float b) {
	return fabs(a - b) < 20;
}

BOOL RectsAreClose(CGRect a, CGRect b) {
	return AreClose(a.size.width, b.size.width) &&
    AreClose(a.size.height, b.size.height) &&
    AreClose(a.origin.x, b.origin.x) &&
    AreClose(a.origin.y, b.origin.y);
}
