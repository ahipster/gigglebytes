import { IRegistryAdapter, SearchQuery } from './interfaces';
import { RegistryRecord, HealthStatus } from '@grip/shared';

export abstract class BaseAdapter implements IRegistryAdapter {
    abstract sourceCode: string;

    abstract searchEntity(query: SearchQuery): Promise<RegistryRecord[]>;
    abstract fetchDetails(id: string): Promise<RegistryRecord | null>;

    async healthCheck(): Promise<HealthStatus> {
        try {
            // Default health check can be overridden
            return 'HEALTHY';
        } catch (error) {
            return 'DOWN';
        }
    }

    protected handleError(error: unknown): void {
        console.error(`[${this.sourceCode}] Error:`, error);
        // Implement standard error reporting/metrics here
    }
}
