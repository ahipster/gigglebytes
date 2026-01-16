import { z } from 'zod';
import {
    EntityStatus,
    SourcingMode,
    SourcingMethod,
    QualityFlag,
    RegistryType,
    ApiType,
    CostModel,
    HealthStatus,
    AuthType,
    VerificationStatus
} from '@prisma/client';

// Re-export Enums
export {
    EntityStatus,
    SourcingMode,
    SourcingMethod,
    QualityFlag,
    RegistryType,
    ApiType,
    CostModel,
    HealthStatus,
    AuthType,
    VerificationStatus
};

// --- Enums as Zod Schemas ---
export const EntityStatusSchema = z.nativeEnum(EntityStatus);
export const SourcingModeSchema = z.nativeEnum(SourcingMode);
export const SourcingMethodSchema = z.nativeEnum(SourcingMethod);
export const QualityFlagSchema = z.nativeEnum(QualityFlag);
export const RegistryTypeSchema = z.nativeEnum(RegistryType);

// --- Base Types ---

export const AddressSchema = z.object({
    addressLine1: z.string().optional(),
    addressLine2: z.string().optional(),
    city: z.string().optional(),
    region: z.string().optional(),
    postalCode: z.string().optional(),
    countryCode: z.string().length(2).optional(),
    rawAddress: z.string().optional(),
    geoLat: z.number().optional(),
    geoLon: z.number().optional()
});
export type Address = z.infer<typeof AddressSchema>;

export const JurisdictionSchema = z.object({
    jurisdictionId: z.string().uuid(),
    isoAlpha2: z.string().length(2),
    isoAlpha3: z.string().length(3).optional().nullable(),
    name: z.string(),
    level: z.enum(['COUNTRY', 'TERRITORY', 'SUPRANATIONAL']),
    parentId: z.string().uuid().optional().nullable()
});
// export type Jurisdiction = z.infer<typeof JurisdictionSchema>; // Use Prisma Type

export const RegistrySourceSchema = z.object({
    sourceId: z.string().uuid(),
    sourceCode: z.string(),
    sourceName: z.string(),
    jurisdictionId: z.string().uuid().optional().nullable(),
    registryType: RegistryTypeSchema,
    apiAvailable: z.boolean().default(false),
    apiType: z.nativeEnum(ApiType).default('NONE').nullable(),
    costModel: z.nativeEnum(CostModel).default('FREE').nullable(),
    healthStatus: z.nativeEnum(HealthStatus).default('UNKNOWN').nullable(),
    isActive: z.boolean().default(true)
});
// export type RegistrySource = z.infer<typeof RegistrySourceSchema>; // Use Prisma Type

export const LegalEntitySchema = z.object({
    entityId: z.string().uuid(),
    internalRef: z.string().optional().nullable(),
    status: EntityStatusSchema.default('ACTIVE'),
    riskRating: z.string().optional().nullable(),
    createdAt: z.date(),
    updatedAt: z.date()
});
// export type LegalEntity = z.infer<typeof LegalEntitySchema>; // Use Prisma Type

export const RegistryRecordSchema = z.object({
    recordId: z.string().uuid(),
    entityId: z.string().uuid(),
    sourceId: z.string().uuid(),
    validFromSource: z.date().optional().nullable(),
    ingestionTs: z.date(),
    sourcingMode: SourcingModeSchema,
    sourcingMethod: SourcingMethodSchema,
    staleFlag: z.boolean().default(false),
    qualityFlag: QualityFlagSchema.default('CLEAN'),
    verificationStatus: z.nativeEnum(VerificationStatus).default('UNVERIFIED'),
    rawPayload: z.record(z.string(), z.unknown()), // JSON
    createdAt: z.date()
});
// export type RegistryRecord = z.infer<typeof RegistryRecordSchema>; // Use Prisma Type

export const MasterEntityRecordSchema = z.object({
    merId: z.string().uuid(),
    entityId: z.string().uuid(),
    version: z.number().int(),
    computedTs: z.date(),

    legalName: z.string().optional().nullable(),
    legalNameLocal: z.string().optional().nullable(),
    tradingName: z.string().optional().nullable(),
    legalForm: z.string().optional().nullable(),
    incorporationDate: z.date().optional().nullable(),
    registrationNumber: z.string().optional().nullable(),
    taxId: z.string().optional().nullable(),
    lei: z.string().length(20).optional().nullable(),
    statusCode: z.string().optional().nullable(),

    registeredAddress: AddressSchema.optional().nullable(),
    businessAddress: AddressSchema.optional().nullable(),

    dqScore: z.number().optional().nullable(),

    createdAt: z.date()
});
// export type MasterEntityRecord = z.infer<typeof MasterEntityRecordSchema>; // Use Prisma Type
