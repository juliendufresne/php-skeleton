<?php

declare(strict_types=1);

namespace App\Logger\Processor;

use Ramsey\Uuid\Uuid;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\RequestStack;

/**
 * Adds a unique identifier for every logs coming from the same console request.
 */
final class RequestIdentifierProcessor
{
    /** @var string|null */
    private $identifier;
    /** @var RequestStack */
    private $requestStack;

    public function __construct(RequestStack $requestStack)
    {
        $this->requestStack = $requestStack;
    }

    public function processRecord(array $record): array
    {
        $record['extra']['request-id'] = $this->getIdentifier();

        return $record;
    }

    private function getIdentifier(): ?string
    {
        if (null !== $this->identifier) {
            return $this->identifier;
        }

        foreach ([$this->requestStack->getCurrentRequest(), $this->requestStack->getMasterRequest()] as $request) {
            if (null !== $request) {
                $this->identifier = $this->extractIdentifierFromRequest($request);

                if (null !== $this->identifier) {
                    return $this->identifier;
                }
            }
        }

        $this->identifier = $this->generateIdentifier();

        return $this->identifier;
    }

    private function extractIdentifierFromRequest(Request $request): ?string
    {
        $candidates = [
            $request->headers->get('X-Request-Id'),
            $request->get('request-id'),
        ];

        foreach ($candidates as $item) {
            if (null !== $item) {
                return $item;
            }
        }

        return null;
    }

    private function generateIdentifier(): string
    {
        return Uuid::uuid4()->toString();
    }
}
