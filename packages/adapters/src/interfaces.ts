import { RegistryRecord, HealthStatus } from '@grip/shared';

export interface SearchQuery {
    name: string;
    jurisdiction?: string;
    registrationNumber?: string;
}

export interface IRegistryAdapter {
    sourceCode: string;

    /**
     * Search for entities in the registry.
     */
    searchEntity(query: SearchQuery): Promise<RegistryRecord[]>;

    /**
     * Fetch full details for a specific record.
     */
    fetchDetails(id: string): Promise<RegistryRecord | null>;

    /**
     * Check if the registry API/Source is healthy.
     */
    healthCheck(): Promise<HealthStatus>;
}
