package org.transitime.core.dataCache;

import java.util.List;

import org.slf4j.Logger;
import org.transitime.core.Indices;

public interface ErrorCache {
	
	Double getErrorValue(Indices indices);

	Double getErrorValue(KalmanErrorCacheKey key);

	void putErrorValue(Indices indices, Double value);
		
	void putErrorValue(KalmanErrorCacheKey key, Double value);

	List<KalmanErrorCacheKey> getKeys();

}