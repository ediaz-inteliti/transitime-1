package org.transitclock.core.dataCache;

import java.util.List;

import org.slf4j.Logger;
import org.transitclock.core.Indices;

public interface ErrorCache {
	
	Double getErrorValue(Indices indices, Boolean travelTime);

	Double getErrorValue(KalmanErrorCacheKey key);

	void putErrorValue(Indices indices, Double value, Boolean travelTime);
		
	void putErrorValue(KalmanErrorCacheKey key, Double value);

	List<KalmanErrorCacheKey> getKeys();

}